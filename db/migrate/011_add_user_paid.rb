class AddUserPaid < ActiveRecord::Migration
  def self.up
    add_column :adults, "paid", :boolean, :default => false
    add_column :adults, "paid_by", :string, :limit => 20
  end

  def self.down
    remove_column :adults, "paid"
    remove_column :adults, "paid_by"
  end
end
