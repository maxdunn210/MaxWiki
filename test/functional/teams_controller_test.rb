require File.dirname(__FILE__) + '/../test_helper'
require 'teams_controller'

# Re-raise errors caught by the controller.
class TeamsController; def rescue_action(e) raise e end; end

class TeamsControllerTest < Test::Unit::TestCase
  fixtures :teams, :wikis, :system

  def setup
    @controller = TeamsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end

  def test_index
    login_admin
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    login_admin
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:teams)
  end

  def test_new
    login_admin
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:team)
  end

  def test_create
    login_admin
    num_teams = Team.count

    post :create, :team => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_teams + 1, Team.count
  end

  def test_edit
    login_admin
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:team)
    assert assigns(:team).valid?
  end

  def test_update
    login_admin
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'
  end

  def test_destroy
    login_admin
    assert_not_nil Team.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Team.find(1)
    }
  end
end
