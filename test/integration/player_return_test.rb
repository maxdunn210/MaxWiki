require File.dirname(__FILE__) + '/../test_helper'

class PlayerReturnTest < ActionController::IntegrationTest
  fixtures :events, :teams, :players, :adults, :doctors, :lookups, :wikis, :system, :revisions, :pages, :wiki_references

if MY_CONFIG[:tric]

  def test_login
    get url_for(:controller => 'reg_admin', :action => 'list_players')
    assert_redirected_to :controller => 'user', :action => 'login'
  end
  
  def test_update_from_reg_admin  
    verify_update_return('reg_admin', 'list_players')
  end
        
  def test_update_from_register
    verify_update_return('register', 'list')
  end
        
  def test_back_button_from_reg_admin
    verify_button_return('reg_admin', 'list_players', 'show', 'Back')
  end

  def test_cancel_button_from_reg_admin
    verify_button_return('reg_admin', 'list_players', 'edit', 'Cancel')
  end

  def test_back_button_from_register
    verify_button_return('register', 'list', 'show', 'Back')
  end

  def test_cancel_button_from_register
    verify_button_return('register', 'list', 'edit', 'Cancel')
  end
end

private
 
  def verify_button_return(list_controller, list_action, action, button)
    login_admin_integrated
    
    get url_for(:controller => list_controller, :action => list_action)
    assert_status_ok
    assert_template list_action
    
    # Make sure Show -> Back works
    get url_for(:controller => 'register', :action => action, :id => 1006)
    assert_status_ok
    assert_template action
    verify_return(button, list_controller, list_action)
  end
  
  def verify_update_return(list_controller, list_action)
    login_admin_integrated
   
    get url_for(:controller => list_controller, :action => list_action)
    assert_status_ok
    assert_template list_action
    
    # Make sure Update works
    post url_for(:controller => 'register', :action => 'update', :id => 1006)
    assert_redirected_to url_for(:controller => list_controller, :action => list_action)
  end  
 
  def assert_status_ok
    assert_equal 200, status, 
    :message => "\nRedirected to #{response.redirected_to.inspect}\nFlash=#{flash[:error]}"
  end

  def assert_reg_admin_player_list    
    assert_redirected_to url_for(:controller => 'reg_admin', :action => 'list_players')
  end  
end
