class AddLookups < ActiveRecord::Migration
  def self.up
    create_table "lookups", :force => false do |t|
      t.column "kind", :string, :limit => 40
      t.column "name", :string, :limit => 40
      t.column "short_name", :string, :limit => 10
      t.column "display_order", :integer
    end
    
    # Change Event columns. For visitor, level and location, need to 
    # remove and replace it so the existing data won't mess up the conversion
    rename_column :events, :team_id, :home_team_id
    
    remove_column :events, :other_team
    add_column :events, :visitor_team_id, :integer
    
    remove_column :events, :location
    add_column :events, :location_id, :integer
    
    # Change Team columns
    remove_column :teams, :level
    add_column :teams, :level_id, :integer

    add_column :teams, :league_id, :integer
  end

  def self.down
  end
end
