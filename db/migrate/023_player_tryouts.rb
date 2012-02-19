class PlayerTryouts < ActiveRecord::Migration
  def self.up
    add_column :players, "tryout_required", :boolean, :default => false
    add_column :players, "tryout_date", :date  
  end
  
  def self.down
    remove_column :players, "tryout_date"
    remove_column :players, "tryout_required"
  end
end
