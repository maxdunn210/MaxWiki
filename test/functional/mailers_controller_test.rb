require File.dirname(__FILE__) + '/../test_helper'
require 'mailers_controller'

# Re-raise errors caught by the controller.
class MailersController; def rescue_action(e) raise e end; end

class MailersControllerTest < Test::Unit::TestCase
  fixtures :mailers, :mailer_groups, :mailer_subscriptions, :emails, :adults, :households, :players, :teams, :lookups

  def setup
    @controller = MailersController.new
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

    get :view, :id => 1
    assert_redirected_to :action => 'login'

    get :edit, :id => 1
    assert_redirected_to :action => 'login'

    post :update, :id => 1
    assert_redirected_to :action => 'login'

    post :destroy, :id => 1
    assert_redirected_to :action => 'login'

    get :send_test, :id => 1
    assert_redirected_to :action => 'login'

    get :process_emails, :id => 1
    assert_redirected_to :action => 'login'
  end

  def test_list
    login_admin
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:mailers)
  end

  def test_new
    login_admin
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:mailer)
  end

  def test_create
    login_admin
    num_mailers = Mailer.count

    post :create, :mailer => {}

    assert_response :redirect
    assert_redirected_to :action => 'view'

    assert_equal num_mailers + 1, Mailer.count
  end

  def test_edit
    login_admin
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:mailer)
    assert assigns(:mailer).valid?
  end

  def test_update
    login_admin
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'view', :id => 1
  end

  def test_destroy
    login_admin
    assert_not_nil Mailer.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Mailer.find(1)
    }
  end
  
  def test_process
    login_admin
    get :process_emails, :id => 1
    assert_no_errors

    assert_tag(:tag => 'p', :content => '9 emails processed', 
    :ancestor => {:tag => 'div', :attributes => {:id => "middle_column"}})

    emails = Email.find(:all, :conditions => {:status => 'Queued'})
    assert_equal(9,emails.size)
  end
end
