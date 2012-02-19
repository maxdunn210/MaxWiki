require File.dirname(__FILE__) + '/../test_helper'
require 'survey_responses_controller'

# Re-raise errors caught by the controller.
class SurveyResponsesController; def rescue_action(e) raise e end; end

class SurveyResponseControllerTest < Test::Unit::TestCase
  fixtures  :surveys, :survey_questions, :survey_responses, :survey_answers
  
  def setup
    @controller = SurveyResponsesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end
  
  def test_need_login
    get :list
    assert_redirected_to :action => 'login'
    
    get :new
    assert_redirected_to :action => 'login'
    
    post :create, :email => {}
    assert_redirected_to :action => 'login'
    
    get :edit, :id => 1
    assert_redirected_to :action => 'login'
    
    post :update, :id => 1
    assert_redirected_to :action => 'login'
    
    post :destroy, :id => 1
    assert_redirected_to :action => 'login'
    
    post :export, :id => 1
    assert_redirected_to :action => 'login'
  end
  
  def test_list
    login_admin
    get :list, :survey_id => 1
    assert_no_errors
    
    assert_tag(:tag => 'h1', :content => "Responses for 'Signup' Survey")
    select = assert_select 'th>a[href]', 1
    assert_equal('Submitter name', select[0].children.to_s)
    
    select = assert_select 'th', 5
    select.delete_at(0)
    assert_equal(["Session", "Topic", "Demo", "Experience"], select.map {|s| s.children.to_s})
    
    select = assert_select 'td>a[href]', 2
    
    # Could be in either order
    if select[0].children.to_s == 'Max Dunn'
      num_md = 0
      num_tj = 1
      num_br = 2
      num_ma = 6
    else
      num_md = 1
      num_tj = 0
      num_br = 7
      num_ma = 1
    end
    
    assert_equal('Max Dunn', select[num_md].children.to_s)
    assert_equal('Thiago Jackiw', select[num_tj].children.to_s)
    
    select = assert_select 'td', 10
    assert_equal('Beginning Ruby on Rails', select[num_br].children.to_s)
    assert_equal('Maybe', select[num_ma].children.to_s)
  end
  
  def test_paging
    login_admin
    get :list, :survey_id => 1
    assert_no_errors
    
    get :list
    assert_no_errors
    assert_tag(:tag => 'h1', :content => "Responses for 'Signup' Survey")
  end
  
  def test_new
    login_admin
    get :new, :survey_id => 1
    assert_no_errors
    assert_template 'new'
    assert_tag(:tag => 'h1', :content => "New Response for 'Signup' Survey")
    assert_response_form
  end
  
  def test_create
    login_admin
    post :create, :survey_id => 1, 
    :survey_response => {"session_id"=>"1001", "submitter_name"=>"New Name 1", "user_id"=>"2"},
    :answers => {"1"=>"Expert", "2"=>"Yes", "3" => "Testing Rails", "4" => "Maybe" }
    assert_no_errors     
    assert_redirected_to :action => 'list'
    
    response = SurveyResponse.find_by_session_id('1001')
    assert_equal("New Name 1", response.submitter_name)
    assert_equal(2, response.user_id)
    assert_equal("Expert", response.find_answer_by_question_id(1).answer)
    assert_equal("Testing Rails", response.find_answer_by_question_id(3).answer)
  end
  
  def test_edit
    login_admin
    get :edit, :id => 1
    assert_no_errors
    
    assert_tag(:tag => 'h1', :content => "Edit Response for 'Signup' Survey")
    select = assert_response_form
    assert_equal('Max Dunn', select[0].attributes['value'])
    assert_equal('1000', select[1].attributes['value'])
    assert_equal('Yes', select[3].attributes['value'])
    assert_equal('Beginning Ruby on Rails', select[4].attributes['value'])
  end
  
  def test_update
    login_admin
    post :update, :id => 1,  :survey_response => {"session_id"=>"1234", "submitter_name"=>"Max Update", "user_id"=>"1"},
    :answers => {"1"=>"Hobbyist", "2"=>"No", "4" => "No" }
    
    assert_no_errors     
    assert_redirected_to :action => 'list'
    response = SurveyResponse.find(1)
    assert_equal('1234', response.session_id)
    assert_equal("Max Update", response.submitter_name)
    assert_equal(1, response.user_id)
    assert_equal("Hobbyist", response.find_answer_by_question_id(1).answer)
    assert_equal("No", response.find_answer_by_question_id(2).answer)
    assert_equal("Beginning Ruby on Rails", response.find_answer_by_question_id(3).answer) # Not changed
    assert_equal("No", response.find_answer_by_question_id(4).answer)
  end
  
  def test_destroy
    login_admin
    assert_not_nil SurveyResponse.find(1)
    assert_equal(4, SurveyAnswer.count(:conditions => {:survey_response_id => 1}))
    
    post :destroy, :id => 1
    assert_no_errors
    assert_redirected_to :action => 'list'
    
    assert_raise(ActiveRecord::RecordNotFound) { SurveyAnswer.find(1) }
    assert_equal(0, SurveyAnswer.count(:conditions => {:survey_response_id => 1}))
  end
  
  def test_export
    login_admin
    get :export, :survey_id => 1
    assert_no_errors
    
    assert_tag(:tag => 'h3', :content => "Signup Survey")
    
    select = assert_select 'th', 6
    assert_equal(["Submitted By", "Submitted On", "Session", "Topic", "Demo", "Experience"], select.map {|s| s.children.to_s} )
    
    select = assert_select 'td', 12
    responses = select.map {|s| s.children.to_s}
    # If responses came up out of order, put in order for checking
    if responses[0] == "Thiago Jackiw"
      (0..5).each do |n|
        responses[n], responses[n+6] = responses[n+6], responses[n]
      end
    end
    assert_equal(["Max Dunn",
     "2006-10-26 20:31",
     "Yes",
     "Beginning Ruby on Rails",
     "Maybe",
     "Expert",
     "Thiago Jackiw",
     "2006-10-20 21:44",
     "Maybe",
     "Searching plug-in",
     "No",
     "Expert"], responses )
  end
  
  #-----------
  private  
  
  def assert_response_form
    select = assert_select 'form>table>tr>td>label', 7
    assert_equal(["Submitter name",
     "User ID",
     "Session ID",
     "Session",
     "Topic",
     "Demo",
     "Experience"], select.map {|s| s.children.to_s})
    
    select = assert_select 'form>table>tr>td>input', 7
    assert_equal(["survey_response[submitter_name]",
     "survey_response[user_id]",
     "survey_response[session_id]",
     "answers[2]",
     "answers[3]",
     "answers[4]",
     "answers[1]"], select.map {|s| s.attributes['name']})

    return select
  end
  
end
