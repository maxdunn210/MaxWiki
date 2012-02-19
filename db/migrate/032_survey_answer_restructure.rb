class SurveyAnswerRestructure < ActiveRecord::Migration
  
  class Survey < ActiveRecord::Base
    has_many :survey_responses
    has_many :survey_answers
    has_many :survey_questions
    ActiveRecord::Base.record_timestamps = false
  end
  
  class SurveyResponse < ActiveRecord::Base
    belongs_to :survey
    has_many :survey_answers
  end
  
  class SurveyResponse < ActiveRecord::Base
    belongs_to :survey
    has_many :survey_answers
    ActiveRecord::Base.record_timestamps = false
  end
  
  class SurveyAnswer < ActiveRecord::Base
    belongs_to :survey
    belongs_to :survey_response
    has_one :survey_question
  end
  
  class OldSurveyAnswer < ActiveRecord::Base; end
  class Adult < ActiveRecord::Base; end
  class Wiki < ActiveRecord::Base; end
  
  # Convert the old answers which were in one table (not normalized) into two normalized tables
  # Look at the timestamp to decide which ones go together
  def self.convert_survey(survey_id)          
    old_survey_answers = OldSurveyAnswer.find(:all, :conditions => {:survey_id => survey_id}, :order => 'updated_at')
    
    last_date = nil
    response = nil
    old_survey_answers.each do |old_survey_answer|
      if last_date != old_survey_answer.updated_at.to_s # Uses 'to_s" to ignore Postgres milliseconds
        last_date = old_survey_answer.updated_at.to_s
        response = SurveyResponse.create(:survey_id => old_survey_answer.survey_id,
                                         :user_id => old_survey_answer.user_id,
                                         :submitter_name => old_survey_answer.submitter_name,
                                         :created_at => old_survey_answer.created_at,
                                         :updated_at => old_survey_answer.updated_at,
                                         :wiki_id => old_survey_answer.wiki_id)
      end
      response.survey_answers.create(:survey_question_id => old_survey_answer.survey_question_id,
                                     :answer => old_survey_answer.response,
                                     :wiki_id => old_survey_answer.wiki_id)
    end
  end
  
  # Convert the old signup questions which were kept in the User (Adult) table
  # For each wiki, create the survey, questions, responses and answers
  OLD_SIGNUP_NAME = 'Old Signup'
  def self.convert_signup(wiki_id)
    survey = Survey.create(:name => OLD_SIGNUP_NAME, :description => 'Old signup survey', :wiki_id => wiki_id)
    
    question_ids = []
     (1..4).each do |num|
      question = survey.survey_questions.create(:name => "Question #{num}",
      :question => "Signup question #{num}",
      :input_type => 'text_field',
      :wiki_id => wiki_id)
      question_ids[num] = question.id
    end
    
    users = Adult.find(:all, :conditions => ['wiki_id = ?', wiki_id])
    users.each do |user|
      next if user.question1.blank? && user.question2.blank? && user.question3.blank? && user.question4.blank? 
    
      response = survey.survey_responses.create(:user_id => user.id,
                                               :submitter_name => ("#{user.firstname} #{user.lastname}").strip,
      :created_at => user.created_at || Time.now,
      :updated_at => user.updated_at || Time.now,
      :wiki_id => wiki_id)
       (1..4).each do |num|
        response.survey_answers.create(:survey_question_id => question_ids[num],
                                       :answer => user.send("question#{num}"),
        :wiki_id => wiki_id)
        
      end      
    end
  end
  
  def self.convert_all
    puts "Converting old surveys"
    surveys = Survey.find(:all)
    all_answers = []
    surveys.each do |survey|
      convert_survey(survey.id)
    end
    
    puts "Converting old signup surveys"
    wikis = Wiki.find(:all, :order => 'id')
    wikis.each do |wiki|
      convert_signup(wiki.id)
    end
  end
  
  def self.up
    rename_table "survey_answers", "old_survey_answers"
    
    create_table "survey_answers", :force => false do |t|
      t.column "survey_id", :integer
      t.column "survey_response_id", :integer
      t.column "survey_question_id", :integer
      t.column "answer", :string
      t.column "wiki_id", :integer
    end  
    
    create_table "survey_responses", :force => false do |t|
      t.column "survey_id", :integer
      t.column "user_id", :integer
      t.column "session_id", :string
      t.column "submitter_name", :string
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
      t.column "wiki_id", :integer
    end
    SurveyResponse.reset_column_information
    
    convert_all
  end
  
  def self.down
    drop_table "survey_answers"
    drop_table "survey_responses"
    rename_table "old_survey_answers", "survey_answers"
    
    puts "Deleting converted signup surveys"
    Survey.delete_all(:name => OLD_SIGNUP_NAME)
  end
end