require File.dirname(__FILE__) + '/../test_helper'
require 'survey_questions_controller'

# Re-raise errors caught by the controller.
class SurveyQuestionsController; def rescue_action(e) raise e end; end

class SurveyQuestionsControllerTest < Test::Unit::TestCase
  fixtures :survey_questions, :surveys
  
  def setup
    @controller = SurveyQuestionsController.new
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
  end
  
  def test_list
    login_admin
    get :list, :survey_id => 1
    
    assert_response :success
    assert_template 'list'
    
    assert_not_nil assigns(:survey_questions)
  end
  
  def test_paging
    login_admin
    get :list, :survey_id => 1
    assert_no_errors
    
    get :list
    assert_no_errors
    assert_tag(:tag => 'h1', :content => "Questions for 'Signup' Survey")
  end
  
  def test_new
    login_admin
    get :new, :survey_id => 1
    
    assert_response :success
    assert_template 'new'
    
    assert_not_nil assigns(:survey_question)
  end
  
  def test_create
    login_admin
    num_survey_questions = SurveyQuestion.count
    
    post :create, :survey_id => 1, :survey_question => {:name => 'Test Question', :question => 'What do you like to do?',
      :display_order => '10', :input_type => 'select', :choices => 'Surf, Snowboard, Mountain Bike', :mandatory => nil, 
      :html_options => nil }
    assert_no_errors
    assert_redirected_to :action => 'list'
    assert_equal num_survey_questions + 1, SurveyQuestion.count
    
    question = SurveyQuestion.find(num_survey_questions+2) # Last one is on a different wiki, so this id will be +2
    assert_equal('Test Question', question.name)
    assert_equal(10, question.display_order)
    assert_equal('select', question.input_type)
  end
  
  def test_edit
    login_admin
    get :edit, :id => 1
    
    assert_response :success
    assert_template 'edit'
    
    assert_not_nil assigns(:survey_question)
    assert assigns(:survey_question).valid?
  end
  
  def test_update
    login_admin
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'
  end
  
  def test_destroy
    login_admin
    assert_not_nil SurveyQuestion.find(1)
    
    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'
    
    assert_raise(ActiveRecord::RecordNotFound) {
      SurveyQuestion.find(1)
    }
  end
end
