class AddPageName < ActiveRecord::Migration
  def self.up
      add_column :lookups, "page_name", :string, :limit => 100
      add_column :teams, "page_name", :string, :limit => 100
  end

  def self.down
  end
end
