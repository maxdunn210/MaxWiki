namespace :db do
  desc "Print the migration version of all databases in 'database.yml'"
  task :schema_version => :environment do
    
    base = ActiveRecord::Base
    
    base.configurations.each do |key, value|
      db = value['database']
      next if db.nil?
      
      base.establish_connection(key)
      
      begin
        @current_db = base.connection.current_database
        @schema_table_found = base.connection.tables.include?('schema_info')
      rescue 
        puts "#{key.capitalize} database had error: #{$!}"
      else  
        unless @schema_table_found
          puts "#{key.capitalize} database is '#{@current_db}' but it doesn't have a 'schema_info' table"
        else
          version = base.connection.select_value('SELECT version FROM schema_info')
          puts "#{key.capitalize} database is '#{@current_db}' version=#{version}"
        end  
      end  
    end
    puts
  end
end