class AddUserAuthProvider < ActiveRecord::Migration
  def self.up
    add_column :adults, "auth_provider", :string
    add_column :adults, "auth_extra", :text
  end

  def self.down
    remove_column :adults, "auth_provider"
    remove_column :adults, "auth_extra"
  end
end
