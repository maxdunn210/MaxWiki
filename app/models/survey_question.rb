class SurveyQuestion < MaxWikiActiveRecord

  belongs_to :wiki
  belongs_to :survey
  has_many :survey_answer_details
  
  def self.find_all_by_survey_id(survey_id)
    find(:all, :conditions => ['survey_id = ?', survey_id], 
     :order => 'display_order')
  end  
  
  def choices_to_a
    if choices.nil? or choices.empty?
      ['Yes','No']
    else    
      choices.split(',').map {|s| s.strip}
    end    
  end
  
  def summable?
    input_type == 'select'
  end
end
