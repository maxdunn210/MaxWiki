class UserTimestamps < ActiveRecord::Migration
  def self.up
    add_column :adults, "created_at", :datetime
    add_column :adults, "updated_at", :datetime
  end

  def self.down
    remove_column :adults, "created_at"
    remove_column :adults, "updated_at"
  end
end
