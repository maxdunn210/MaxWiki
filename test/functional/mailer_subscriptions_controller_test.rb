require File.dirname(__FILE__) + '/../test_helper'
require 'mailer_subscriptions_controller'

# Re-raise errors caught by the controller.
class MailerSubscriptionsController; def rescue_action(e) raise e end; end

class MailerSubscriptionsControllerTest < Test::Unit::TestCase
  fixtures :mailer_subscriptions

  def setup
    @controller = MailerSubscriptionsController.new
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

    assert_not_nil assigns(:mailer_subscriptions)
  end

  def test_new
    login_admin
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:mailer_subscription)
  end

  def test_create
    login_admin
    num_mailer_subscriptions = MailerSubscription.count

    post :create, :mailer_subscription => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_mailer_subscriptions + 1, MailerSubscription.count
  end

  def test_edit
    login_admin
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:mailer_subscription)
    assert assigns(:mailer_subscription).valid?
  end

  def test_update
    login_admin
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'
  end

  def test_destroy
    login_admin
    assert_not_nil MailerSubscription.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      MailerSubscription.find(1)
    }
  end
end
