require File.dirname(__FILE__) + '/../test_helper'

class AdminTest < ActionController::IntegrationTest
  fixtures :wikis, :system, :revisions, :pages, :wiki_references, :adults
  
  # Most create wiki tests are in functional/admin_controller_test
  # This just tests that after creating a new wiki, we can immediately login as the admin user since
  # this was causing a problem at one time
  def test_login_new_wiki
    password = 'new_wiki_password'
    setup_host('new.maxwiki.com')
    
    post url_for(:controller => 'admin', :action => 'create_wiki',
    #'wiki[name]' => 'maxwiki', 
    'wiki[description]' => 'MaxWiki New', 
    'email' => 'test@test.com', 'theme' => 'maxwiki', 
    'password' => password, 'password_confirmation' => password)
    assert_no_errors
    assert_redirected_to url_for(:controller => 'user', :action => 'login')
    
    login_integrated('admin', password)
    assert_no_errors
    assert_redirected_to url_for(:controller => 'wiki', :action => 'show', :link => 'welcome')
  end
  
  # This test makes sure that when switching between different multi_host wikis, the correct 
  # "current_wiki" is set on the models
  def test_current_wiki
    setup_host('www.maxwiki.com')
    sess1 = open_session 
    sess1.get sess1.url_for(:controller => 'wiki', :action => 'show',  :link => 'welcome')
    sess1.assert_response(:success)
    sess1.assert_equal(1, MaxWikiActiveRecord.current_wiki.id)
    sess1.assert_equal(1, User.current_wiki.id)
    
    setup_host('www.maxwiki2.com')
    sess2 = open_session 
    sess2.get sess2.url_for(:controller => 'wiki', :action => 'show', :link => 'welcome')
    sess2.assert_response(:success)
    sess2.assert_equal(2, MaxWikiActiveRecord.current_wiki.id)
    sess2.assert_equal(2, User.current_wiki.id)
  end
  
  def test_create_wiki
    Wiki.delete_all
    get url_for(:controller => 'wiki', :action => 'show', :link => 'HomePage')
    assert_no_errors
    assert_redirected_to url_for(:controller => 'admin', :action => 'create_wiki')
    follow_redirect!
    get url_for(:controller => 'admin', :action => 'create_wiki')
    
    assert_tag(:tag => 'form', :attributes => {:action => "/_action/admin/create_wiki"})
    input_tags = find_all_tag(:tag => 'input')
    assert_equal(["wiki[description]", "email", "password", "password_confirmation", "commit"],
      input_tags.map {|i| i['name']})
      
    description = "Test Wiki Description"
    email = "test@email.com"
    password = "mypassword"  
    password_confirmation = "mypassword"  
    
    post url_for(:controller => 'admin', :action => 'create_wiki', 'wiki[description]' => description, 
      :email => email, :password => password, :password_confirmation => password) 
    
    wiki = Wiki.find(:first)
    assert_equal('maxwiki', wiki.name)
    assert_equal(description, wiki.description)
  end
  
  
end
