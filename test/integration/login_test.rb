require File.dirname(__FILE__) + '/../test_helper'

class LoginTest < ActionController::IntegrationTest
  fixtures :system, :wikis, :pages, :revisions, :adults
  
  NEW_PAGE = 'New Page'
  NEW_PAGE_LINK = 'new_page'
  
  def test_home_page
    get '/_action/user/login'
    assert_no_errors
    
    login_integrated
    follow_redirect!
    assert_no_errors
    assert_equal(flash[:notice], 'Login successful')
    
    get 'welcome'
    select = assert_select('div#middle_column>p')
    assert_equal('You are now logged in to Test Web Site as &lsquo;Admin Dunn&rsquo; with role &lsquo;Admin&rsquo;.', select[0].children.to_s)
  end
 
end
