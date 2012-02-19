class UpdateEvents2 < ActiveRecord::Migration
  def self.up
    change_column :events, "note", :string, :limit => 200
    add_column :events, "home_team_note", :string, :limit => 200
    add_column :events, "visitor_team_note", :string, :limit => 200
  end

  def self.down
  end
end
