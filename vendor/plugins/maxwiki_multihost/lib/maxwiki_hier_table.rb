# This module will sort the tables in the database so that the ones at lower levels reference
# ones higher. This is used for migrations so that we can process the higher tables first and store a mapping
# of their old id numbers to their new ids so the ids can be relocated.
# 
# In order for this to work, all ":belongs_to" relations must be setup, even if it is not used. This
# also ensures that we will map the correct column name to the referencing table, even when the
# foreign_key has a non-standard name
# 
# The algorithm works by finding all the other tables that a table references. It then creates
# a list of inherited tables by recursively walking through the list of referenced tables. Then
# we can simply sort the tables by the number of tables in this inherited_table list. This will 
# guarantee the correct order since a table that references another table cannot have the same 
# number of inherited tables because it will have all the tables that the inherited table 
# references, plus one more - the inherited table itself.
# 
# Limitations: This will blow up on self-referential tables, or tables that reference each other
# 

module Maxwiki
  module HierTable
  
      class HierTables < Array
        def initialize(db)
          super([])
          db.connection.tables.each {|table| self << HierTable.new(table)}
          
          self.each do |table|
             table.inherited_tables = get_inherited_tables(table.name)
          end   
          self.sort!
        end  
        
        # Given the table name, return the HierTable for it
        def find_hier_table(name)
          find {|table| table.name == name}
        end
        
        # Recursively build a list of all tables this table references and the tables that its
        # references reference
        def get_inherited_tables(start_name)
          hier_table = find_hier_table(start_name)
          
          inherited = []
          unless hier_table.blank? || hier_table.referenced_tables.blank?
            inherited << hier_table.referenced_tables - [start_name]
            hier_table.referenced_tables.each do |table_name|
              next if table_name == start_name
              inherited << get_inherited_tables(table_name)
            end  
          end
          inherited.flatten.compact.uniq
        end
      end
      
      class HierTable
        include Comparable
        attr_reader :name
        attr_reader :model
        attr_reader :associations
        attr_reader :referenced_tables
        attr_accessor :inherited_tables
        
        def initialize(name)
          @name = name
          @model = name.classify.constantize rescue nil
          if @model.nil?
            @referenced_tables = []
          else  
            
            # This requires that all :belongs_to associations are setup
            @associations = @model.reflect_on_all_associations(:belongs_to)
            @referenced_tables = @associations.map {|association| association.table_name}.uniq
            
            #This doesn't give us the referenced table names if different from the link name
            #@referenced_tables = klass.column_names.map {|col_name| col_name =~ /(.*)_id$/ ? $1 : nil}.compact 
          end
        end
        
        def primary_keys(table_name)
          @associations.map {|association| association.table_name == table_name ? association.primary_key_name : nil}.compact
        end
        
        def <=>(other)
          inherited_tables.size <=> other.inherited_tables.size
        end
      end
    end
 end
  
  