# This adds these rake tasks:
# 
# rake maxwiki:list
# rake maxwiki:export_all
# rake maxwiki:merge
# rake maxwiki:wiki:delete
# rake maxwiki:wiki:export

#------- NameSpace maxwiki -----------  
namespace :maxwiki do

  CHANGE_ENV_MSG = 'change environment with RAILS_ENV=production'
    
  #------------------  
  desc "List wikis - " + CHANGE_ENV_MSG
  task :list => :environment do
     change_environment

     Wiki.find(:all).each do |wiki|
       puts "Name=#{wiki.name}, WIKI_ID=#{wiki.id}, Description=#{wiki.description}"
     end
  end
        
  #------------------  
  desc "Export all wikis - " + CHANGE_ENV_MSG
  task :export_all => :environment do
    include Maxwiki::ExportMerge
    change_environment

    Wiki.find(:all).each do |wiki|
      ENV["WIKI_ID"] = wiki.id.to_s
      Rake::Task["maxwiki:wiki:export"].execute
    end  
    
  end
  
  #------------------  
  desc "Merge a wiki - use with FILE=maxwiki " + CHANGE_ENV_MSG
  task :merge => :environment do
    include Maxwiki::ExportMerge
    change_environment
    
    yaml_file = ENV["FILE"]
    
    if yaml_file.blank?
      raise "Enter the name of the file you want to import\n" + 
        "like 'rake maxwiki:merge FILE=maxwiki'\n" +
        "This file should have been created with rake maxwiki:wiki:export function\n" +
        "If the path is not specified, 'db' will be assumed. If the extension is\n" +
        "not specified, 'yml' will be assumed"
    end
    
    yaml_file = expand_yaml_filename(yaml_file)
    
    unless File.exists?(yaml_file)
      raise "The file '#{yaml_file}' not found"
    end

    db_env = 'test'
  
    puts "Merging #{yaml_file} into database '#{ActiveRecord::Base.connection.current_database}'"
    puts "Purging temp database"
    with_env(db_env) do
      Rake::Task["db:test:purge"].invoke
    end  
    
    version = YAML.load_file(yaml_file)["schema_info"][0]["version"]
    
    puts "Migrating temp database to version #{version}"
    with_env(db_env, 'VERSION' => version.to_s) do
      Rake::Task["db:migrate"].execute
    end
    
    puts "Importing data to temp database"
    import_to_temp(yaml_file)

    Rake::Task["maxwiki:merge_from_temp"].execute
  end  
    
  desc "Merge from temp - " + CHANGE_ENV_MSG
  task :merge_from_temp => :environment do
    include Maxwiki::ExportMerge
    change_environment
    db_env = 'test'
    
    puts "Migrating temp database to latest version "
    with_env(db_env, 'VERSION' => nil) do
      Rake::Task["db:migrate"].execute
    end  
        
    puts "Merging temp database"
    merge(:show_status)
    
    puts "Merge done"
  end

  #------- NameSpace wiki -----------  
  namespace :wiki do

    LIST_TASK_MSG = "(Use 'rake maxwiki:list' to see a list of wikis)"
    SPECIFY_WIKI_MSG =  'specify with WIKI_ID=10002 '
    
    #------------------  
    desc "Export a wiki - " + SPECIFY_WIKI_MSG + CHANGE_ENV_MSG
    task :export => :environment do
      include Maxwiki::ExportMerge
      change_environment

      wiki_id = ENV["WIKI_ID"]

      if wiki_id.blank?
        raise "Enter the WIKI_ID of the wiki you want to export\n" + 
          "  like 'rake maxwiki:wiki:export WIKI_ID=10002'\n" + LIST_TASK_MSG
      end
      
      wiki = wiki_find(wiki_id)
      if wiki.nil?
        raise "No wiki found with WIKI_ID=#{wiki_id}\n" + LIST_TASK_MSG
      end   
      
      export_filename = generate_export_filename(wiki.name)
      
      STDOUT.puts "Exporting #{wiki.description} with WIKI_ID=#{wiki_id} to #{export_filename}"
      export_wiki(wiki.id, export_filename)
    end

    #------------------  
    desc "Delete a wiki - " + SPECIFY_WIKI_MSG + CHANGE_ENV_MSG
    task :delete => :environment do
      include Maxwiki::ExportMerge
      change_environment

      wiki_id = ENV["WIKI_ID"]

      if wiki_id.blank?
        raise "Enter the WIKI_ID of the wiki you want to delete\n" + 
          "  like 'rake maxwiki:wiki:delete WIKI_ID=10002'\n" + LIST_TASK_MSG
      end
      
      wiki = wiki_find(wiki_id)
      if wiki.nil?
        STDOUT.puts "No wiki found with WIKI_ID=#{wiki_id}\n" + LIST_TASK_MSG
        STDOUT.print "Would you like to cleanup all records with wiki_id #{wiki_id}? (y/N): "
      else
        db_name = ActiveRecord::Base.connection.current_database
        STDOUT.print "Are you sure you want to delete all pages and records for\n" +
          "'#{wiki.description}' with name '#{wiki.name}' and wiki_id '#{wiki.id}' in the #{RAILS_ENV} database '#{db_name}'? (y/N): "
      end    
      
      answer = STDIN.gets
      if answer[0,1].downcase != 'y'
        raise
      end    
      
      delete_wiki(wiki_id, :show_status)
    end
    
  end
end

# ------- Helpers ------------------  

def generate_export_filename(base_name)
  date_str = Date.today.to_s
  dir = base_name.include?('/') ? '' : 'db/'
  try_name = "#{dir}#{base_name}_#{date_str}"
  ext = '.yml'
  serial_str = ''
  serial = 1
  
  while File.exist?(try_name + serial_str + ext)
    serial_str = '_v' + serial.to_s
    serial += 1
  end
  
  try_name + serial_str + ext
end

def expand_yaml_filename(name)
  dir = name.include?('/') ? '' : 'db/'
  ext = name.include?('.') ? '' : '.yml'
  dir + name + ext
end    
    


def change_environment
   rails_env = ENV["RAILS_ENV"]
   ActiveRecord::Base.establish_connection(rails_env) unless rails_env.blank?
end     


def with_env(db_env, env_hash = {})
  ActiveRecord::Base.establish_connection(db_env)
  ActiveRecord::Schema.verbose = false
  old_env = ENV
  env_hash.each {|key, value| ENV[key] = value}
  
  yield

  ENV.replace(old_env)
  ActiveRecord::Base.establish_connection(ENV["RAILS_ENV"] || RAILS_ENV)
end

def wiki_find(wiki_id)
  wiki = Wiki.find(:first, :conditions => ['id = ?', wiki_id])
end      
