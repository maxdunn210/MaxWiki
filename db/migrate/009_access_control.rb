class AccessControl < ActiveRecord::Migration
  def self.up
    add_column :pages, "access_read", :string, :limit => 40, :default => "Public"
    add_column :pages, "access_write", :string, :limit => 40, :default => "Editor"
    add_column :pages, "access_permissions", :string, :limit => 40, :default => "Admin"
  end

  def self.down
    remove_column :pages, "access_read"
    remove_column :pages, "access_write"
    remove_column :pages, "access_permissions"
  end
end
