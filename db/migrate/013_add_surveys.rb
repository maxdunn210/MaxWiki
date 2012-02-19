class AddSurveys < ActiveRecord::Migration
  def self.up
    create_table "surveys", :force => false do |t|
      t.column "name", :string, :length => 20
      t.column "description", :string
      t.column "submit_page", :string
      t.column "ask_at_signup", :boolean
    end  

    create_table "survey_questions", :force => false do |t|
      t.column "name", :string, :length => 20
      t.column "question", :string
      t.column "display_order", :integer
      t.column "survey_id", :integer
      t.column "input_type", :string
      t.column "choices", :string
      t.column "mandatory", :boolean
      t.column "html_options", :string
    end  

    create_table "survey_answers", :force => false do |t|
      t.column "survey_id", :integer
      t.column "survey_question_id", :integer
      t.column "response", :string
      t.column "user_id", :integer
      t.column "submitter_name", :string
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end  
  end

  def self.down
    drop_table "surveys"
    drop_table "survey_questions"
    drop_table "survey_answers"
  end
end
