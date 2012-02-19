class SurveyResponse < MaxWikiActiveRecord
  belongs_to :wiki
  belongs_to :survey
  has_many :survey_answers, :dependent => :delete_all
  
  def self.find_all_by_survey_id(survey_id)
    find(:all, :conditions => ['survey_id = ?', survey_id], :order => 'id')
  end  
  
  def find_answer_by_question_id(question_id)
    survey_answers.find(:first, :conditions => ['survey_question_id = ?', question_id])
  end
  
  def find_answer_by_question_name(question_name)
    question = survey.survey_questions.find(:first, :conditions => ['name = ?', question_name])
    return nil if question.nil?
    find_answer_by_question_id(question.id)
  end
  
  def collect_answers
    # Get the question ids in display order
    question_ids = survey.survey_questions.map {|q| q.id}
    
    # Now find the answers in the same order as the questions 
    answers = []
    question_ids.each do |question_id| 
      answer = find_answer_by_question_id(question_id)
      answer_text = answer.nil? ? '' : answer.answer
      answers << answer_text
    end
    return answers
  end  
  
  def add_or_update_answer(question, answer_text)
    # question can either be the question id number, or the question name
    if question.to_i != 0 
      answer = find_answer_by_question_id(question.to_i)
    else
      answer = find_answer_by_question_name(question)
    end
    
    # if new, then question needs to be the question ID number
    if answer.nil?
      answer = survey_answers.build(:survey_question_id => question.to_i)
    end
    answer.update_attributes!(:answer => answer_text)
  end
  
  def save_answers(params)
    return if params.nil?
    params.each do |question, response|
      add_or_update_answer(question, response)
    end
    update_attribute(:updated_at, Time.now) # Update the "updated_at" field in the answer record
  end
  
end
