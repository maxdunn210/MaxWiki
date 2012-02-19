require File.dirname(__FILE__) + '/../test_helper'

class SurveyTest < ActionController::IntegrationTest
  fixtures :wikis, :system, :adults, :pages, :revisions,  :wiki_references, 
  :surveys, :survey_questions, :survey_responses, :survey_answers
  
  def test_show_survey
    get url_for(:controller => 'wiki', :action => 'show', :link => 'survey')
    assert_no_errors
    
    assert_tag_middle_col(:tag => 'form', :attributes => {:action => "/_action/surveys/save_answers"})
    assert_tag_middle_col(:tag => 'input', :attributes => {:id => 'survey_id', :name => 'survey_id', 
      :type => 'hidden', :value => '1'})
    
    assert_tag_form(:tag => 'label', :content => 'Would you consider leading a session?')
    session_tag = {:tag => "select", :attributes => {:id => "answers[2]"}}
    assert_tag_form(session_tag)
    tags = find_all_tag(:tag => 'option', :parent => session_tag)
    assert_equal(['No', 'Yes', 'Maybe'], tags.map {|t| t.children.to_s})
    
    assert_tag_form({:tag => "textarea", :attributes => {:id => "answers[3]"}})
    assert_tag_form({:tag => "select", :attributes => {:id => "answers[4]"}})
    assert_tag_form({:tag => "select", :attributes => {:id => "answers[1]"}})
  end
  
  def test_show_results
    get url_for(:controller => 'wiki', :action => 'show', :link => 'surveyresults')
    assert_no_errors
    assert_tag_middle_col(:tag => 'p', :content => 'Total responses=2')
    assert_tag_middle_col(:tag => 'td', :content => 'Just interested=0%, Hobbyist=0%, Use for work=0%, Expert=100%')
    assert_tag_middle_col(:tag => 'td', :content => 'No=0%, Yes=50%, Maybe=50%')
    assert_tag_middle_col(:tag => 'td', :content => 'No=50%, Yes=0%, Maybe=50%')
  end
  
  def test_survey_defaults
    login_integrated('max@test.com')
    get url_for(:controller => 'wiki', :action => 'show', :link => 'survey')
    assert_no_errors
    assert_tag(:tag => 'option', :attributes => {:value => "Expert", :selected => "selected"})
  end
  
  def test_save_answers
    survey = Survey.find(1)
    num_of_responses = survey.survey_responses.size
    
    login_integrated('editor@test.com')

    # In Rails 1.2.1 there is a bug that causes url_for in IntegrationTest to turn nested hashes into a string. 
    # So setup the 'questions' the long way
    post url_for(:controller => 'surveys', :action => 'save_answers',
    'survey_id' => '1', 'answers[Session]' => 'Yes', 'answers[Topic]' => "Intermediate RoR", 
    'answers[Demo]' => "Maybe", 'answers[Experience]' => "Hobbyist")
    assert_no_errors
    
    survey = Survey.find(1)
    assert_equal(num_of_responses + 1, survey.survey_responses.size, "Didn't add new response")
    
    response = survey.survey_responses[num_of_responses]
    assert_equal(1008, response.user_id)
    assert_equal(32, response.session_id.size)
    assert_equal('Max Dunn Editor', response.submitter_name)
    
    assert_equal(["Hobbyist", "Intermediate RoR", "Maybe", "Yes"], response.survey_answers.map {|a| a.answer}.sort)
  end
  
  #----------  
  private
  
  def assert_tag_form(tag)
    assert_tag(tag.merge({:ancestor => {:tag => 'form', :attributes => {:action => "/_action/surveys/save_answers"}}}))
  end  
  
end
