require File.dirname(__FILE__) + '/../test_helper'
require 'mailer_groups_controller'

# Re-raise errors caught by the controller.
class MailerGroupsController; def rescue_action(e) raise e end; end

class MailerGroupsControllerTest < Test::Unit::TestCase
  fixtures :mailer_groups

  def setup
    @controller = MailerGroupsController.new
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

    assert_not_nil assigns(:mailer_groups)
  end

  def test_new
    login_admin
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:mailer_group)
  end

  def test_create
    login_admin
    num_mailer_groups = MailerGroup.count

    post :create, :mailer_group => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_mailer_groups + 1, MailerGroup.count
  end

  def test_edit
    login_admin
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:mailer_group)
    assert assigns(:mailer_group).valid?
  end

  def test_update
    login_admin
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'
  end

  def test_destroy
    login_admin
    assert_not_nil MailerGroup.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      MailerGroup.find(1)
    }
  end
end
