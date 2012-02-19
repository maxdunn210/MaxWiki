class UserQuestions < ActiveRecord::Migration
  def self.up
    add_column :adults, "company", :string, :limit => 60
    add_column :adults, "question1", :string
    add_column :adults, "question2", :string
    add_column :adults, "question3", :string
    add_column :adults, "question4", :string
  end

  def self.down
    remove_column :adults, "company"
    remove_column :adults, "question1"
    remove_column :adults, "question2"
    remove_column :adults, "question3"
    remove_column :adults, "question4"
  end
end
