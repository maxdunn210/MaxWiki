require File.dirname(__FILE__) + '/../test_helper'

class Session
  attr_accessor :session_id
end

class SurveyTest < Test::Unit::TestCase
  fixtures :surveys, :survey_questions, :survey_responses, :survey_answers, :wikis
  
  def test_wiki_links
    survey = Survey.new
    assert_equal 1, survey.wiki_id, "Wrong wiki_id"
  end  
  
  def test_list
    assert_equal(["Signup", "TwoDay", "Volunteer"], Survey.list)
  end
  
  def test_add_or_update_response
    answer_hash = {'1' => 'New question 1', '3' => 'New question 3'}
    user = User.find(1000)
    session = Session.new
    survey = Survey.find(1)
    survey.add_or_update_response(answer_hash, user, session)
    
    response = SurveyResponse.find(1)
    assert_equal(["Yes", "New question 3", "Maybe", "New question 1"], response.collect_answers)
  end
  
  def test_find_response
    survey = Survey.find(1)
    user = User.find(1000)
    session = Session.new
    session.session_id = '12345'
    
    assert_equal(1, survey.find_response(user, session).id)
    assert_equal(2, survey.find_response(nil, session).id)
    session.session_id = '0'
    user = User.find(1003)
    assert_equal(nil, survey.find_response(user, session))
  end
  
  def test_find_response_or_create
    survey = Survey.find(1)
    user = User.find(1000)
    session = Session.new
    
    assert_equal(1, survey.find_response_or_create(user, session).id)
    count = SurveyResponse.count
    assert_equal(count + 1, survey.find_response_or_create(nil, nil).id)
    assert_equal(count + 1, SurveyResponse.count)
  end
  
  def test_gather_answers
    survey = Survey.find(1)
    gathered = survey.gather_answers
    assert_equal(["Max Dunn-Yes", "Thiago Jackiw-Maybe"], gathered.map {|g| g[:submitter_name] + '-' + g[:answers][0]}.sort)
  end
end
