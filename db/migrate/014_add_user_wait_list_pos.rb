class AddUserWaitListPos < ActiveRecord::Migration
  def self.up
    add_column :adults, "wait_list_pos", :integer, :default => 0
  end

  def self.down
    remove_column :adults, "wait_list_pos"
  end
end
