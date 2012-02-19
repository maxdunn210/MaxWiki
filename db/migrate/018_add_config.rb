class AddConfig < ActiveRecord::Migration

  class Web < ActiveRecord::Base
  end
  
  def self.up
    add_column :webs, "config", :text

    Web.reset_column_information
    web = Web.find(:first)
    unless web.nil?
      web.config = MY_CONFIG
      web.save!
    end  
  end

  def self.down
    remove_column :webs, "config"  
  end
end
