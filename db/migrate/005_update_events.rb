class UpdateEvents < ActiveRecord::Migration
  def self.up
    # Change length column to integer. Since there is string data in there now
    # can't simply change the type because it will produce a conversion error
    # So instead, remove then add the column
    remove_column :events, :length
    add_column :events, :length, :integer
    
    # Don't need "home" anymore, since the home team will always be in the 
    # home_team_id column
    remove_column :events, :home
    
    # Cleanup some other names
    rename_column :events, :event_type, :kind
    rename_column :events, :event_name, :name
  end

  def self.down
  end
end
