require './test/test_helper'

class WebdavAuthTest < Test::Unit::TestCase
  
  fixtures :adults
  
  def setup
    @controller = UserController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    @request.host = "localhost"
    super
    
    @wiki.config[:xythos_url] = 'http://local.xythos.com:8080'
    @wiki.config[:xythos_authentication] = '/Users/#{login}@maxwiki.com'
    @wiki.config[:xythos_principal] = '/xythoswfs/principals/ldap/maxwiki.com/#{login}'
    @wiki.config[:default_role] = 'Editor'
    @wiki.save!
  end
  
  #----------------------
  # Webdav auth tests
  #----------------------
  def test_auth
    auth = MaxWiki::WebdavAuth.authenticate('bkeller', 'welcome', nil)
    assert(!auth.error?, auth.error_msg)
    assert_equal('Bill', auth.attributes[:firstname])
    assert_equal('Keller', auth.attributes[:lastname])
    assert_equal('Editor', auth.attributes[:role])
  end
  
  def test_bad_user
    auth = MaxWiki::WebdavAuth.authenticate('nobody', 'welcome', nil)
    assert_equal(Authorization::NOT_AUTHORIZED, auth.error_type, auth.error_msg)
  end
  
  def test_bad_pass
    auth = MaxWiki::WebdavAuth.authenticate('bkeller', 'none', nil)
    assert_equal(Authorization::NOT_AUTHORIZED, auth.error_type, auth.error_msg)
  end
  
  def test_no_pass
    auth = MaxWiki::WebdavAuth.authenticate('bkeller', '', nil)
    assert_equal(Authorization::NOT_AUTHORIZED, auth.error_type, auth.error_msg)
  end
  
  #----------------------
  # Webdav login tests
  #----------------------
  WEBDAV_LOGIN = 'bkeller'
  WEBDAV_PASSWORD = 'welcome'
  
  def test_login_webdav
    login_user_controller(WEBDAV_LOGIN, WEBDAV_PASSWORD)
    user = User.find_by_login(WEBDAV_LOGIN)
    assert(user)
    assert_equal('Bill', user.firstname)
    assert_equal('Keller', user.lastname)
    assert_equal('Editor', user.role)  
    assert_equal('MaxWiki::WebdavAuth', user.auth_provider)  
    assert_equal(1, user.verified)  
    assert_equal(0, user.deleted)  
  end
  
  def test_login_webdav_twice
    login_user_controller(WEBDAV_LOGIN, WEBDAV_PASSWORD)
    user1 = User.find_by_login(WEBDAV_LOGIN)
    
    login_user_controller(WEBDAV_LOGIN, WEBDAV_PASSWORD)
    user2 = User.find_by_login(WEBDAV_LOGIN)
    
    assert_equal(user1.id, user2.id)
  end  
  
  def test_webdav_edit
    login_user_controller(WEBDAV_LOGIN, WEBDAV_PASSWORD)
    check_edit(WEBDAV_LOGIN)
  end
  
  #----------------------
  private
  
  def check_edit(login)  
    new_firstname = 'Max'
    new_lastname = 'Dunn'
    new_email = 'new@domain.com'
    old_user = User.find_by_login(login)
    
    get :edit
    assert_template 'edit'
    
    post :edit, "user" => {:firstname => new_firstname, :lastname => new_lastname, 
      :email => new_email, :login => 'should_not_change', :password => "shouldntchange"}
    assert_redirected_to :action => 'my_account'
    follow_redirect
    user = User.find_by_login(login)
    assert_equal(new_firstname, user.firstname)
    assert_equal(new_lastname, user.lastname)
    assert_equal(new_email, user.email)
    assert_equal(old_user.login, user.login)
    assert_equal(old_user.salted_password, user.salted_password)
    assert_match("You are now logged in to Local - Test Web Site as 'Max Dunn' with role '#{old_user.role}'",@response.body[/<h1>My Account<\/h1>.*?<\/p>/m])
  end
  
end
