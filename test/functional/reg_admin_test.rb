require File.dirname(__FILE__) + '/../test_helper'
require 'reg_admin_controller'

# Re-raise errors caught by the controller.
class RegAdminController; def rescue_action(e) raise e end; end

class RegAdminTest < Test::Unit::TestCase
  fixtures :adults, :players, :households, :doctors, :wikis, :system

  def setup
    @controller = RegAdminController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end

  def test_paid
  
    get :index
    assert_redirected_to :controller => 'user', :action => 'login'
    
    login_admin
    get :index
    assert_template 'index'

    assert_tag(:tag => 'div', :attributes => {:id => "middle_column"},
      :content => 'Total users paid: 0')    
  end

end
