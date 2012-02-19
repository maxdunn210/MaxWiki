class AddTeams < ActiveRecord::Migration
  def self.up
    create_table "teams", :force => false do |t|
      t.column "name", :string, :limit => 40
      t.column "level", :string, :limit => 20
      t.column "manager", :string, :limit => 60
    end
    add_column :players, :team_id, :integer

  end

  def self.down
  end
end
