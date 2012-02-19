require File.dirname(__FILE__) + '/../test_helper'
require 'surveys_controller'

# Re-raise errors caught by the controller.
class SurveysController; def rescue_action(e) raise e end; end

class SurveysControllerTest < Test::Unit::TestCase
  fixtures :surveys
  
  def setup
    @controller = SurveysController.new
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
    get :list
    
    assert_response :success
    assert_template 'list'
    
    assert_not_nil assigns(:surveys)
  end
  
  def test_new
    login_admin
    get :new
    
    assert_response :success
    assert_template 'new'
    
    assert_not_nil assigns(:survey)
  end
  
  def test_create
    login_admin
    num_surveys = Survey.count
    
    post :create, :survey => {}
    
    assert_response :redirect
    assert_redirected_to :action => 'list'
    
    assert_equal num_surveys + 1, Survey.count
  end
  
  def test_edit
    login_admin
    get :edit, :id => 1
    
    assert_response :success
    assert_template 'edit'
    
    assert_not_nil assigns(:survey)
    assert assigns(:survey).valid?
  end
  
  def test_update
    login_admin
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'
  end
  
  def test_destroy
    login_admin
    assert_not_nil Survey.find(1)
    
    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'
    
    assert_raise(ActiveRecord::RecordNotFound) {
      Survey.find(1)
    }
  end
end
