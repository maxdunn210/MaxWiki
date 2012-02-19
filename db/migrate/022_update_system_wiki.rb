class UpdateSystemWiki < ActiveRecord::Migration
  def self.up
    add_column :system, "name", :string 
    add_column :system, "description", :string  
    add_column :system, "config", :text  
    remove_column :system, "password"  
    
    rename_column :wikis, "name", "description"
    rename_column :wikis, "address", "name"
    remove_column :wikis, "password"  
  end

  def self.down
    remove_column :system, "name"
    remove_column :system, "description"
    remove_column :system, "config"
    add_column :system, "password", :string

    rename_column :wikis, "name", "address"
    rename_column :wikis, "description", "name"
    add_column :wikis, "password", :string
  end
end
