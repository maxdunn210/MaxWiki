class AddLocationsUsages < ActiveRecord::Migration
  def self.up
    create_table "locations", :force => false do |t|
      t.column "name", :string, :length => 40
      t.column "short_name", :string, :length => 10
      t.column "parent_location_id", :integer
    end

    create_table "usages", :force => false do |t|
      t.column "location_id", :integer
      t.column "value", :float
      t.column "kind", :string
    end
  end

  def self.down
    drop_table "locations"
    drop_table "usages"
  end
end
