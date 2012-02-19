class SurveyRemoveAskAtSignup < ActiveRecord::Migration
  def self.up
    remove_column :surveys, "ask_at_signup"
  end
  
  def self.down
    add_column :surveys, "ask_at_signup", :boolean
  end
end
