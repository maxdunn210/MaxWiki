class AddTitle < ActiveRecord::Migration
  def self.up
    add_column :pages, "add_title", :string, :length => 20
  end

  def self.down
    remove_column :pages, "add_title"
  end
end
