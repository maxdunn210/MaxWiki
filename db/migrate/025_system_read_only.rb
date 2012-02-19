class SystemReadOnly < ActiveRecord::Migration
  def self.up
    add_column :system, "read_only_mode", :string
    add_column :system, "read_only_msg", :string
  end
  
  def self.down
    remove_column :system, "read_only_mode"
    remove_column :system, "read_only_msg"
  end
end
