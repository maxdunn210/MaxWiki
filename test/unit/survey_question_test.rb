require File.dirname(__FILE__) + '/../test_helper'

class SurveyQuestionTest < Test::Unit::TestCase
  fixtures :survey_questions, :wikis
  
  def test_wiki_links
    survey_question = SurveyQuestion.new
    assert_equal 1, survey_question.wiki_id, "Wrong wiki_id"
    
    if ACTIVE_PLUGINS.include?('maxwiki_multihost')
      num = 11
    else
      num = 5
    end
    assert_equal(num,SurveyQuestion.count)
  end  
  
  def test_find
    assert_equal(4, SurveyQuestion.find_all_by_survey_id(1).size)
  end
  
  def test_other
    question = SurveyQuestion.find(2)
    assert_equal(["No", "Yes", "Maybe"], question.choices_to_a)
    assert(question.summable?)
    assert(!SurveyQuestion.find(3).summable?)
  end
  
end
