require File.dirname(__FILE__) + '/../test_helper'
require 'wiki_config_controller'

# Re-raise errors caught by the controller.
class WikiConfigController; def rescue_action(e) raise e end; end

class WikiConfigControllerTest < Test::Unit::TestCase
  fixtures :wikis, :system
  
  def setup
    @controller = WikiConfigController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end
  
  def test_authorization
    get :index
    assert_redirected_to :controller => 'user', :action => 'login'
    
    get :config
    assert_redirected_to :controller => 'user', :action => 'login'
    
    post :update
    assert_redirected_to :controller => 'user', :action => 'login'
  end
  
  def test_index
    login_admin
    get :index
    assert_no_errors
    assert_list_item('Main', '/_action/wiki_config/config?template=main')
    if ACTIVE_PLUGINS.include?('maxwiki_webdav_auth')
      assert_list_item('Xythos Authorization', '/_action/wiki_config/config?template=webdav_auth_config')
    end
  end
  
  def test_config_forms
    login_admin
    check_config_form('main', 'Main Configuration', 'site_name', 'Test Web Site')
    check_config_form('signup', 'Signup', 'signup_survey', 'Signup', 'select')
    if ACTIVE_PLUGINS.include?('maxwiki_webdav_auth')
      check_config_form('webdav_auth_config', 'Xythos Authorization Configuration', 'xythos_authentication', 'http://local.xythos.com:8080/Users/#{login}@maxwiki.com')
    end
  end
  
  def test_update
    new_name = "New Name"
    login_admin
    
    post :update, :config => {:site_name => new_name}
    assert_no_errors
    assert_template nil
    @wiki.reload # reload the @wiki object to pickup the new values
    assert_equal(new_name, @wiki.config[:site_name])
  end
  
  #------------------
  private
  
  def assert_list_item(name, href)
    assert_tag(:tag => 'div', :attributes => {:id => "middle_column"}, 
    :descendant => {:tag => 'a', :attributes => {:href => href}, :content => name})
  end
  
  def check_config_form(template_name, title, item_name, item_value, item_type = 'input')
    get :config, :template => template_name
    assert_no_errors
    assert_tag(:tag => 'h1', :content => title)
    assert_tag(:tag => 'form', :attributes => {:action => '/_action/wiki_config/update', :method => "post"})
    assert_tag(:tag => 'input', :attributes => {:name => 'template', :type => 'hidden', :value => template_name})
    if item_type == 'select'
      assert_tag(:tag => 'select', :attributes => {:name => "config[#{item_name}]"}, 
        :child => {:tag => 'option', :attributes => {:value => item_value}} )
    else
      assert_tag(:tag => 'input', :attributes => {:name => "config[#{item_name}]", :type => 'text', :value => item_value})
    end
  end
end
