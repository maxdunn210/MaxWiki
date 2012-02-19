require File.dirname(__FILE__) + '/../test_helper'
require 'admin_controller'

# Re-raise errors caught by the controller.
class AdminController; def rescue_action(e) raise e end; end

class AdminControllerTest < Test::Unit::TestCase
  fixtures :adults, :wikis, :system
  
  def setup
    @controller = AdminController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end
  
  def test_create_existing_system
    get :create_system
    assert_equal('System has already been created.', flash[:error])
  end  
    
  def test_create_system
    System.delete_all
    get :create_system
    assert_no_errors
    
    system = System.find(:first)
    assert_equal('maxwiki_system', system.name)
    
    System.delete_all
    put :create_system, :system => {:name => 'new_system'}
    assert_no_errors
    system = System.find(:first)
    assert_equal('new_system', system.name)
  end
  
  def test_create_wiki
    get :create_wiki
    assert_response(:success)
    assert_template('create_wiki')
    assert_msg_error("Wiki 'maxwiki' has already been created.")
    
    Wiki.delete_all
    get :create_wiki
    assert_no_errors
    
    put :create_wiki, :wiki => {:description => 'MaxWiki'}, :email => 'test@test.com',
    :theme => 'maxwiki', :password => 'password', :password_confirmation => 'password'
    assert_no_errors
  end
  
end
