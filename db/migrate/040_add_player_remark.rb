class AddPlayerRemark < ActiveRecord::Migration
  def self.up
    add_column :players, "remarks", :string, :limit => 100, :default => ""
  end

  def self.down
    remove_column :players, "remarks"
  end
end
