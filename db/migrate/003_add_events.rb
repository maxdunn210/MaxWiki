class AddEvents < ActiveRecord::Migration
  def self.up
    create_table "events", :force => false do |t|
      t.column "event_type", :string, :limit => 40
      t.column "event_name", :string, :limit => 40
      t.column "date_time", :datetime
      t.column "length", :string, :limit => 20
      t.column "team_id", :integer
      t.column "location", :string, :limit => 40
      t.column "other_team", :string, :limit => 40
      t.column "home", :boolean
      t.column "note", :string, :limit => 1024
    end
    
    drop_table "users"
 end

  def self.down
  end
end
