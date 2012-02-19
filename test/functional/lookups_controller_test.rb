require File.dirname(__FILE__) + '/../test_helper'
require 'lookups_controller'

# Re-raise errors caught by the controller.
class LookupsController; def rescue_action(e) raise e end; end

class LookupsControllerTest < Test::Unit::TestCase
  fixtures :lookups, :wikis, :system

  def setup
    @controller = LookupsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end

  def test_list_lookup
    login_admin
    get :list_lookups

    assert_template 'list_lookups'
    assert_response :success

    assert_not_nil assigns(:lookups)
  end

  def test_new_lookup
    login_admin
    get :new_lookup

    assert_template 'new_lookup'
    assert_response :success
    assert_not_nil assigns(:lookup)
  end

  def test_create
    login_admin
    num_lookups = Lookup.count

    post :create_lookup, :lookup => {}

    assert_redirected_to :action => 'list_lookups'

    assert_equal num_lookups + 1, Lookup.count
  end

  def test_edit_lookup
    login_admin
    get :edit_lookup, :id => 1

    assert_template 'edit_lookup'
    assert_response :success

    assert_not_nil assigns(:lookup)
    assert assigns(:lookup).valid?
  end

  def test_update_lookup
    login_admin
    post :update_lookup, :id => 1
    assert_redirected_to :action => 'list_lookups'
  end

  def test_destroy_lookup
    login_admin
    assert_not_nil Lookup.find(1)

    post :destroy_lookup, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list_lookups'

    assert_raise(ActiveRecord::RecordNotFound) {
      Lookup.find(1)
    }
  end
end
