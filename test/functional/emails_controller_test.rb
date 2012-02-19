require File.dirname(__FILE__) + '/../test_helper'
require 'emails_controller'

# Re-raise errors caught by the controller.
class EmailsController; def rescue_action(e) raise e end; end

class EmailsControllerTest < Test::Unit::TestCase
  fixtures :emails, :wikis, :system

  def setup
    @controller = EmailsController.new
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
    assert_no_errors
    
    select = assert_select 'div#middle_column>div.scroll_area>table>tr>td>a[href]', 2
    assert_equal(["suzy@test.com", "joe@test.com"], select.map {|s| s.children.to_s})      
  end

  def test_new
    login_admin
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:email)
  end

  def test_create
    login_admin
    num_emails = Email.count

    post :create, :email => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_emails + 1, Email.count
  end

  def test_edit
    login_admin
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:email)
    assert assigns(:email).valid?
  end

  def test_update
    login_admin
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'
  end

  def test_destroy
    login_admin
    assert_not_nil Email.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Email.find(1)
    }
  end
end
