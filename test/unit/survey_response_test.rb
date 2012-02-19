require File.dirname(__FILE__) + '/../test_helper'

class SurveyResponseTest < Test::Unit::TestCase
  fixtures :surveys, :survey_questions, :survey_responses, :survey_answers, :wikis
  
  def test_wiki_link
    response = SurveyResponse.new
    assert_equal(1, response.wiki_id, "Wrong wiki_id")
  end  
  
  def test_find
    responses = SurveyResponse.find_all_by_survey_id(1)
    assert_equal(2, responses.size)
    assert_equal('Max Dunn', responses[0].submitter_name)
    assert_equal('Thiago Jackiw', responses[1].submitter_name)
    
    response = SurveyResponse.find(1)
    answer = response.find_answer_by_question_id(1)
    assert_equal('Expert', answer.answer)
    
    answer = response.find_answer_by_question_name('Experience')
    assert_equal('Expert', answer.answer)
  end
  
  def test_answers
    answers = SurveyResponse.find(1).collect_answers
    assert_equal(["Yes", "Beginning Ruby on Rails", "Maybe", "Expert"], answers)
  end
  
  def test_add_or_update_answer
    response = SurveyResponse.find(1)
    count = SurveyAnswer.count
    
    response.add_or_update_answer(1, "Updated answer by id")
    assert_equal(count, SurveyAnswer.count)
    response = SurveyResponse.find(1)
    assert_equal("Updated answer by id", response.find_answer_by_question_id(1).answer)
    
    response.add_or_update_answer('Experience', "Updated answer by name")
    assert_equal(count, SurveyAnswer.count)
    response = SurveyResponse.find(1)
    assert_equal("Updated answer by name", response.find_answer_by_question_name('Experience').answer)
    
    SurveyAnswer.delete(1)
    assert_equal(count - 1, SurveyAnswer.count)
    response.add_or_update_answer(1, "Added answer")
    assert_equal(count, SurveyAnswer.count)
    response = SurveyResponse.find(1)
    assert_equal("Added answer", response.find_answer_by_question_id(1).answer)
  end
  
  def test_save_answers
    response = SurveyResponse.find(1)
    response.save_answers({'1' => 'New question 1', '3' => 'New question 3'})

    response = SurveyResponse.find(1)
    assert_equal(["Yes", "New question 3", "Maybe", "New question 1"], response.collect_answers)
    assert_equal(Time.now.to_s, response.updated_at.to_s)
  end  
end
