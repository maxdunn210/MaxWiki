require 'active_record/fixtures'

class AddLocationsUsagesData < ActiveRecord::Migration
  def self.up
    directory = File.join(File.dirname(__FILE__), "data")
    Fixtures.create_fixtures(directory, "locations")
    Fixtures.create_fixtures(directory, "usages")
  end

  def self.down
    Usage.delete_all
    Location.delete_all
  end
end
