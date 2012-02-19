# These methods do exporting and merging of one wiki into another system.
# 
# It is designed mainly to be run from Rake, but can also be run from the application too. If so,
# then when merging the application will need to empty the test database and call "rake db:migrate"
# appropriately.
# 
# Currently it uses the YAML format. However, it should be straightforward to add support for JSON or XML.
# 
# When exporting, it will only back the indicated wiki. For backing up the entire system, use a
# database dump.
# 
# In order for merging to work, it needs a valid "test" database setup in database.yml and 
# all ":belongs_to" relationships setup, even if they are not used. Otherwise, the ids will not be
# relinked.
#
# Strategy to merge another wiki:
# 
# 1. Get a temp database. (Currently using the test database in database.yml)
# 2. Delete all tables
# 3. Read the first part of the backup file and get the schema_info version
# 4. Run rake db:migrate VERSION=version to update the database to the same version as the imported data
# 5. Import records from yaml file and write to database using SQL (we don't want to use ActiveRecord because
#    some of the models may have changed
# 6. Run rake db:migrate again to bring the tempory database up to the current version
# 7. Put the tables in hierarchical order
# 8. Load records from the temp database and one by one, create new objects and add to existing table
# 9. Keep a hash of the ID mappings
# 10. When writing records, search for and fixup secondary ids
# 
# Note: Since this normally will be done from Rake, it currently uses Rake to do the migration. 
# If we want to run it from the application, we will need to shell out to Rake to do the migration
# 
# Here are the advantages of handling merges this way:
# 
# * Can move data between different hosts because ids are relocated so they won't conflict with existing records
# * Handles moving data to a different type of database (i.e. MySQL to Postgres)
# * Allows importing from older schemas
# * Can do it online while users are still using the database and adding new records
# 
#  Issues:
#  
#  * Can't handle self referencing tables or tables that reference each other. To do this, we would
#    need to go back to tables already written and patch the reference ids
#  * For many operations, it pulls the whole table, or even all the tables, into memory. For use
#    with wikis that have lots of data, it should be rewritten to process data in smaller blocks.

require 'maxwiki_hier_table'
module Maxwiki
  module ExportMerge
    
    include Maxwiki::HierTable
    
    SCHEMA_TABLES = ['schema_info', 'schema_migrations', 'plugin_schema_info']
    OKAAPI_TABLES = ['concepts', 'cvectors', 'document_to_words', 'documents',
    'dvectors', 'temp_concepts', 'temp_words', 'word_to_documents', 'words']
    EXPORT_IMPORT_SPECIAL_TABLES = ['sessions', 'old_survey_answers'] + SCHEMA_TABLES + OKAAPI_TABLES
    NO_WIKI_ID_TABLES = ['system', 'locations', 'usages'] + EXPORT_IMPORT_SPECIAL_TABLES
    
    # Setup a class just to use a different database connection
    # Initially set it to the 'test' database in the database.yml file
    class MyActiveRecord < ActiveRecord::Base
      self.abstract_class = true
      establish_connection("test")
    end
    
    # We don't want to export as objects, because when we import we will use sql to insert back into the
    # tables. Otherwise, if an model object has been renamed, it will bomb.
    #  schema_info needs to be the first document in the YAML file.
    def export_wiki(wiki_id = nil, export_name = nil)
      wiki_id ||= @wiki.id
      @export_file = export_name ||  "db/#{@wiki.name}.yml" #Debug
      f = File.new(@export_file, "w+")
      
      # There is no model for schema_info and plugin_schema_info, so fake them
      data = {"schema_info" => [{"version" => ActiveRecord::Migrator.current_version}]}
      YAML::dump(data, f)   
      data = {"plugin_schema_info" => ActiveRecord::Base.connection.select_all('SELECT * FROM plugin_schema_info')}
      YAML::dump(data, f)   
      
      # Dump an empty session table so the table will be reconstructed on import
      data = {"sessions" => []}
      YAML::dump(data, f)   
      
      # Dump system 
      
      tables_to_export = ActiveRecord::Base.connection.tables.sort - NO_WIKI_ID_TABLES
      
      tables_to_export.each do |tbl|
        tbl_class = tbl.classify.constantize rescue nil
        next if tbl_class.nil?
        
        if tbl == 'wikis'
          data = {tbl => [tbl_class.find(wiki_id).attributes]}
        else
          data = {tbl => tbl_class.find(:all, :conditions => ['wiki_id = ?', wiki_id]).map {|o| o.attributes}}
        end  
        YAML::dump(data, f)
      end
      
      f.close
    end
    
    def delete_wiki(wiki_id, show_status = false)
      ActiveRecord::Base.connection.tables.each do |table|
        next if NO_WIKI_ID_TABLES.include?(table)
        
        begin
          table_class = table.classify.constantize
          if table == 'wikis'
            num = table_class.delete_all(['id = ?', wiki_id])
          else
            num = table_class.delete_all(['wiki_id = ?', wiki_id])
          end
          puts "Deleted #{num} records with wiki_id #{wiki_id} from #{table}" if show_status
          
        rescue => e
          puts "Error deleting records with wiki_id #{wiki_id} from #{table}: #{e}" if show_status
        end
        
      end
    end
    
    # Before this is called, all the data in the database should be dropped and
    # it should be brought up to the version in the import file (with rake:db:migrate VERSION=12)
    # After this is called, the database should be migrated to the current version
    def import_to_temp(yaml_file)
      
      # Make sure we are connected to the test database so we don't wipe out another one by accident
      #MyActiveRecord.establish_connection("test")
      
      MyActiveRecord.transaction do 
        f = File.open(yaml_file)
        YAML.load_documents(f) do |doc|
          next if doc.nil?
          
          table_name = doc.keys[0]
          rows = doc.values[0]
          
          unless SCHEMA_TABLES.include?(table_name)
            reset_primary_key(MyActiveRecord, table_name)
            rows.each do |row|
              sql_insert(MyActiveRecord, table_name, row)
            end  
            reset_primary_key(MyActiveRecord, table_name)
          end
        end        
      end  
    end   
    
    def sql_insert(base, table_name, row)    
      base.connection.insert "INSERT INTO #{table_name} (#{row.keys.collect { |key| MyActiveRecord.connection.quote_column_name(key) }.join(",")}) VALUES (#{row.values.collect { |value| MyActiveRecord.connection.quote(value) }.join(",")})"
    end  
    
    def clear_database(active_record)
      active_record.connection.tables.each do |table|
        active_record.connection.drop_table(table)
      end  
    end
    
    def reset_primary_key(db, table_name)
      if db.connection.respond_to?(:reset_pk_sequence!)
        db.connection.reset_pk_sequence!(table_name)
      end
    end
    
    
    class MissingId < Exception;end
    
    # This merges in the records from the 'test' database and relocates the ids. 
    # This database needs to be the same version as the one we are merging into.
    # Use import_to_temp for this. The records will be imported into the 
    # current database (based on the RAILS_ENV) unless ActiveRecord::Base.establish_connection
    # is called to use a differnent database.
    # 
    # We can't use ActiveRecord here to do this because it will blowup on composite fields,
    # like the Revisions.author field. Instead, use straight SQL
    
    def merge(show_status = false)
      mapping = {}
      tables = HierTables.new(MyActiveRecord)
      
      # Save a list of all the existing wiki names so that we can make sure the 
      # one we are merging has a unique name
      wiki_names = Wiki.find(:all).map {|wiki| wiki.name}
      
      # Go through each table
      ActiveRecord::Base.transaction do
        tables.each do |table|
          next if NO_WIKI_ID_TABLES.include?(table.name)
          
          # Go through each item in table
          rows = MyActiveRecord.connection.select_all("SELECT * FROM #{table.name}")
          
          if rows == 0 and table_name == 'wikis' 
            raise "Table 'wikis' has no entries!"
          end
          
          rows.each do |attributes|
            
            # Make sure the wiki.name is unique since this is how wikis are selected
            if table.name == 'wikis'
              attributes['name'] = make_unique(wiki_names, attributes['name'])
              puts "Wiki name is #{attributes['name']}" if show_status
            end
            
            # Go through all referenced tables and patch the ids
            # However, if a new_id is not found, it means that the parent record was deleted and 
            # this is an orphan record. (Except for household_id in the adults table.) So don't insert it.
            begin
              table.referenced_tables.each do |referenced_table|
                table.primary_keys(referenced_table).each do |key|
                  old_id = attributes[key]
                  new_id = mapping["#{referenced_table}_#{old_id}"]
                  if new_id.nil? && 
                   (['revisions', 'wiki_references'].include?(table.name) && referenced_table == 'pages')
                    puts "Skipping record #{attributes['id']} in table #{table.name} because it references missing id #{old_id} from #{referenced_table}" if show_status
                    raise MissingId 
                  end  
                  attributes[key] = new_id
                end  
              end
              
              old_primary_id = attributes.delete('id')
              new_primary_id = sql_insert(ActiveRecord::Base, table.name, attributes)
              
              # Save the wiki id so we can show in message below
              @new_wiki_id = new_primary_id if table.name == 'wikis'
              
              # Save the id mapping of the new item just inserted
              mapping["#{table.name}_#{old_primary_id}"] = new_primary_id
              
            rescue MissingId
              # Do nothing here, just continue with the next row
            end  
          end  
          
          puts "Merged #{rows.size} records with wiki_id #{@new_wiki_id} into #{table.name}" if show_status
        end
      end
    end
    
    
    #--------------------
    private
    
    def make_unique(names, name)
      suffix_str = ''
      serial = 1
      while names.include?(name + suffix_str)
        suffix_str = "_#{serial}"
        serial += 1
      end
      name + suffix_str
    end
    
  end
end