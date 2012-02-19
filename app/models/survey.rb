class Survey < MaxWikiActiveRecord
  
  belongs_to :wiki
  has_many :survey_questions, :order => 'display_order'
  has_many :survey_answers
  has_many :survey_responses
  
  def self.list
    self.find(:all, :order => 'name').map {|s| s.name}
  end
  
  def add_or_update_response(answer_hash, user, session)
    answer = find_response_or_create(user, session)
    answer.save_answers(answer_hash)
  end          
  
  def find_response(user, session)
    response = nil
    if !user.nil?
      response = survey_responses.find(:first, :conditions => ['user_id = ?', user.id])
    elsif !session.nil? && response.nil?
      response = survey_responses.find(:first, :conditions => ['session_id = ?', session.session_id])
    end
	return response  
  end
  
  def find_response_or_create(user, session)
    response = find_response(user, session)
    
    user_id = nil
    session_id = nil
    submitter_name = nil
    
    if response.nil?
      unless user.nil?
        submitter_name = user.full_name
        user_id = user.id 
      end  
      unless session.nil?
        session_id = session.session_id
      end
      response = survey_responses.create(:user_id => user_id, :session_id => session_id,
                                     :submitter_name => submitter_name)
    end
    return response
  end
  
  def gather_answers
    gathered = []
    survey_responses.each do |response|
      gather = response.attributes.symbolize_keys
      gather[:answers] = response.collect_answers
      gathered << gather
    end
    return gathered
  end  
  
end
