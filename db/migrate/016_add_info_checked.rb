class AddInfoChecked < ActiveRecord::Migration
  def self.up
    add_column :players, "info_checked", :boolean
  end

  def self.down
    remove_column :players, "info_checked"
  end
end
