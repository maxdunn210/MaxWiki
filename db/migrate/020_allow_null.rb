class AllowNull < ActiveRecord::Migration
  def self.up
    change_column "adults", "email", :string, :limit => 60, :default => "", :null => true
    change_column "adults", "household_id", :integer, :default => 0, :null => true
    change_column "adults", "adultnum", :integer, :default => 0, :null => true
    change_column "doctors", "household_id", :integer, :default => 0, :null => true
    change_column "players", "household_id", :integer, :default => 0, :null => true
  end

  def self.down
    change_column "adults", "email", :string, :limit => 60, :default => "", :null => false
    change_column "adults", "household_id", :integer, :default => 0, :null => false
    change_column "adults", "adultnum", :integer, :default => 0, :null => false
    change_column "doctors", "household_id", :integer, :default => 0, :null => false
    change_column "players", "household_id", :integer, :default => 0, :null => false
  end
end
