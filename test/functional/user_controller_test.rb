require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../mocks/test/time'
require File.dirname(__FILE__) + '/../mocks/test/email_test'

require 'user_controller'

# Raise errors beyond the default web-based presentation
class UserController; def rescue_action(e) raise e end; end

class UserControllerTest < Test::Unit::TestCase
  
  fixtures :adults, :wikis, :system, :surveys, :survey_questions, :survey_responses, :survey_answers
  
  # Need to turn off transactions for test_import because it
  # also uses a transaction to roll back the database changes in in MySQL
  # and transactions cannot be nested
  self.use_transactional_fixtures = false
  
  NEW_EMAIL = 'new_signup@test.com'
  NEW_LOGIN = NEW_EMAIL
  BOGUS_KEY = '1234567890123456789012345678901234567890'
  SHORT_KEY = '123456789012345678901234567890123456789'  
  FIRSTNAME = 'Joe'
  LASTNAME = 'Smith'
  
  def setup
    @controller = UserController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    super
  end
  
  def test_login_admin(login='admin@test.com', password='password')
    login_user_controller(login, password)
    assert Role.check_role(ROLE_ADMIN)
    assert Role.check_role(ROLE_EDITOR)
  end
  
  def test_login_editor(login='editor@test.com', password='password')
    login_user_controller(login, password)
    assert !Role.check_role(ROLE_ADMIN)
    assert Role.check_role(ROLE_EDITOR)
  end
  
  def test_auth_bob
    # @request.session[:return_to] = "/bogus/location"
    login_user_controller("bob", "atest")
    #assert_redirected_to("http://#{@request.host}/bogus/location")
    assert_redirected_to_welcome
  end
  
  def test_edit
    get :edit
    assert_redirected_to :action => 'login'
    
    post :edit,  {:firstname => 'foo'}
    assert_redirected_to :action => 'login'
    
    login = 'bob'    
    login_user_controller(login, "atest")
    check_edit(login)
  end
  
  def test_bad_email
    bad_email = 'bad_email.domain'
    bad_email_msg = 'Email is invalid'
    post :signup, "user" => { "firstname" => FIRSTNAME, "lastname" => LASTNAME, "password" => "newpassword", "password_confirmation" => "newpassword", 
      "email" => bad_email}
    assert_redirected_to :action => 'signup'
    follow_redirect
    assert_msg_error(bad_email_msg)
    
    login = 'bob'    
    login_user_controller(login, "atest")
    
    post :edit,  "user" => {:email => bad_email}
    assert_template 'edit'
    assert_msg_error(bad_email_msg)
  end
  
  def test_delete
    login1 = "deletebob1"
    login2 = "deletebob2"
    password = "alongtest"  
    ActionMailer::Base.deliveries = []
    
    # Immediate delete
    login_user_controller(login1, password)
    UserSystem::CONFIG[:delayed_delete] = false
    post :delete, :confirm => 'yes'
    assert_no_errors
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert @response.session[:user].nil?
    login_user_controller(login1, password, false)
    
    # Now try delayed delete
    ActionMailer::Base.deliveries = []
    login_user_controller(login2, password)
    UserSystem::CONFIG[:delayed_delete] = true
    post :delete, :confirm => 'yes'
    assert_no_errors
    assert_equal 1, ActionMailer::Base.deliveries.size
    id, key = get_id_and_key_from_email
    get :restore_deleted, :id => id, :key => "badkey"
    assert @response.session[:user].nil?
    
    # Advance the time past the delete date
    Time.advance_by_days = UserSystem::CONFIG[:delayed_delete_days]
    get :restore_deleted, :id => id, :key => key
    Time.advance_by_days = 0
    assert_redirected_to :action => 'login'
    assert @response.session[:user].nil?
    
    get :restore_deleted, :id => id, :key => key
    assert_no_errors
    
    login_user_controller(login2, password)
    assert_no_errors
    assert @response.session[:user]
  end
  
  def test_signup
    ActionMailer::Base.deliveries = []
    post :signup, "user" => { "firstname" => FIRSTNAME, "lastname" => LASTNAME, "password" => "newpassword", "password_confirmation" => "newpassword", 
      "email" => NEW_EMAIL }
    assert_no_errors
    assert_response :success
    assert_template 'wait_for_email'
    assert @response.session[:user].nil?
    assert_equal 2, ActionMailer::Base.deliveries.size
    check_email(FIRSTNAME, LASTNAME, NEW_EMAIL, NEW_LOGIN)
    id, key = get_id_and_key_from_email
    user = User.find_by_email(NEW_EMAIL)
    assert_not_nil user
    assert_equal 0, user.verified, "Verified is wrong for user with email #{NEW_EMAIL} "
    assert_equal id, user.id, "User ID in the email is not the same"
    
    # First past the expiration.
    Time.advance_by_days = 1
    get :complete_signup, "id" => id, "key" => key
    Time.advance_by_days = 0
    user = User.find_by_email(NEW_EMAIL)
    assert_equal 0, user.verified, "User was verified incorrectly with expired token"
    assert_redirected_to :action => 'verify_signup'
    follow_redirect
    assert_msg_error('This authentication key has expired.')
    
    # Then a bogus key.
    get :complete_signup, "id" => id, "key" => BOGUS_KEY
    user = User.find_by_email(NEW_EMAIL)
    assert_equal 0, user.verified
    assert_redirected_to :action => 'verify_signup'
    follow_redirect      
    assert_msg_error('The authentication key is incorrect and is likely too old.')
    
    # Now a short key
    get :complete_signup, "id"=> id, "key" => SHORT_KEY
    user = User.find_by_email(NEW_EMAIL)
    assert_equal 0, user.verified
    assert_redirected_to :action => 'verify_signup'
    follow_redirect      
    assert_msg_error('This authentication key is too short.')
    
    # Now the real one.
    get :complete_signup, "id"=> id, "key" => "#{key}"
    user = User.find_by_email(NEW_EMAIL)
    assert_equal 1, user.verified
    assert_redirected_to :action => 'login'
    follow_redirect  
    assert_msg_notice('Your account is now activated.')
    
    post :login, "user" => {"login" => NEW_LOGIN, "password" => "newpassword" }
    assert_redirected_to_welcome
    assert @response.session[:user][:id] == user.id
    get :logout
  end
  
  def test_multiple_cc_addresses
    ActionMailer::Base.deliveries = []
    email1 = 'test1@maxtest.com'
    email2 = 'test2@testmax.com'
    @wiki.config[:signup_cc_to] = "#{email1}, #{email2}"   
    @wiki.save!    
    
    post :signup, "user" => { "firstname" => FIRSTNAME, "lastname" => LASTNAME, "password" => "newpassword", "password_confirmation" => "newpassword", 
      "email" => NEW_EMAIL }
    assert_no_errors
    
    # The test delivery doesn't send two emails so just check the addresses
    mail = ActionMailer::Base.deliveries[1]
    assert_equal([email1, email2], mail.to_addrs.map {|a| a.to_s}.sort)
  end
  
  def test_signup_survey
    @wiki.config[:signup_survey] = 'Signup'    
    @wiki.save!
    
    get :signup
    assert_no_errors
    assert_tag(:tag => 'select', :attributes => {:id => 'answers[2]'})
    assert_tag(:tag => 'textarea', :attributes => {:id => 'answers[3]', :cols => '40', :rows => '2'})
    assert_tag(:tag => 'select', :attributes => {:id => 'answers[4]'})
    assert_tag(:tag => 'select', :attributes => {:id => 'answers[1]'})
    
    post :signup, "user" => { "firstname" => FIRSTNAME, "lastname" => LASTNAME, 
      "password" => "newpassword", "password_confirmation" => "newpassword", "email" => NEW_EMAIL},
      "survey_id" => "1",
       "answers" => {"Session" => "Yes", "Topic" => "Beginning RoR", "Demo" => "Yes", "Experience" => "Use for work"}
    assert_no_errors
    assert_template 'wait_for_email'
    
    survey = Survey.find(1)
    response = survey.survey_responses[2]
    
    assert_equal('Joe Smith', response.submitter_name)
    assert_equal(["Beginning RoR", "Use for work", "Yes", "Yes"], response.survey_answers.map {|a| a.answer}.sort)
  end
  
  def test_signup_bad_password
    ActionMailer::Base.deliveries = []
    post :signup, "user" => { "login" => NEW_LOGIN, "password" => "bad", 
      "password_confirmation" => "bad", "email" => NEW_EMAIL }
    assert_redirected_to :action => 'signup'
    follow_redirect
    
    assert @response.session[:user].nil?
    assert_response :success
    assert_template 'signup'
    assert_equal 0, ActionMailer::Base.deliveries.size
  end
  
  def test_signup_bad_email
    ActionMailer::Base.deliveries = []
    ActionMailer::Base.inject_one_error = true
    post :signup, "user" => { "login" => NEW_LOGIN, "password" => "newpassword", 
      "password_confirmation" => "newpassword", "email" => NEW_EMAIL }
    assert_redirected_to :action => 'signup'
    follow_redirect
    
    assert @response.session[:user].nil?
    assert_equal 0, ActionMailer::Base.deliveries.size
  end
  
  def test_change_password
    do_change_password(false, false)
    do_change_password(true, false)
    do_change_password(false, true)
  end
  
  def test_reset_password
    do_reset_password({:bad_address => false, :bad_email => false, :logged_in => true})
    do_reset_password({:bad_address => false, :bad_email => false, :logged_in => false})
    do_reset_password({:bad_address => true, :bad_email => false, :logged_in => false})
    do_reset_password({:bad_address => false, :bad_email => true, :logged_in => false})
  end
  
  def test_bad_signup_password
    @request.session[:return_to] = "/bogus/location"
    new_email = "test_new@test.com"
    used_email = "max@test.com"
    email_taken_msg = "Email has already been taken"
    bad_password_msg = "Password doesn't match confirmation"
    
    post :signup, :user => { :email => new_email, :password => "newpassword", :password_confirmation => "wrong" }
    assert_redirected_to :action => 'signup'
    follow_redirect
    assert_template "signup"
    assert_msg_error(bad_password_msg)
    assert_no_msg_error(email_taken_msg)
    
    # Need to blank out the last_signup_url or the next call to user/signup will mess up. The reason is that
    # posts like above don't normally have the parameters in the URL but are passed in the form instead,
    # and having a "user" has as a parameter confuses request.request_uri 
    session[:last_signup_url] = nil
    
    post :signup, :user => { :email => used_email, :password => "newpassword", :password_confirmation => "newpassword" }
    assert_redirected_to :action => 'signup'
    follow_redirect
    assert_no_msg_error(bad_password_msg)
    assert_msg_error(email_taken_msg)
    
    post :signup, :user => { :email => new_email, :password => "newpassword", :password_confirmation => "newpassword" }
    assert_response :success
    assert_template "wait_for_email"
    assert_no_msg_error(bad_password_msg)
    assert_no_msg_error(email_taken_msg)
  end
  
  def test_invalid_login
    post :login, :user => { :login => "bob", :password => "not_correct" }
    assert @response.session[:user].nil?
    assert_template "login"
  end
  
  def test_login_logoff
    login_user_controller("bob", "atest")
    logout_user_controller
  end
  
  def test_import
    emails = %w{email_error@test.com new_test@test.com good@domain.com bad@email max@test.com}
    ActionMailer::Base.deliveries = []
    ActionMailer::Base.inject_one_error = true
    
    # Make sure it requires an admin role
    post :import, :emails => emails.join(', ')
    assert_redirected_to :action => 'login'
    
    # Login and post some emails
    login_admin
    post :import, :emails => emails.join(', ')
    assert_template 'import_done'
    
    #Make sure that the result page shows the correct emails
    test_section = @response.body[/<h2>Added<\/h2>.*?<\/ul>/m]
    assert_match("<li>new_test@test.com</li>\n\n  <li>good@domain.com</li>", test_section)
    
    test_section = @response.body[/<h2>Problems<\/h2>.*?<\/ul>/m]
    assert_match("<li>email_error@test.com - Failed to send email</li>\n\n  <li>max@test.com - Duplicate</li>", test_section)
    
    # This first one had an email error so make sure it didn't create a user
    assert_equal(nil, User.find_by_email(emails[0]))
    
    # This was good, check all the fields
    user = User.find_by_email(emails[1])
    assert_equal(emails[1], user.login)
    assert_equal('new_test', user.firstname)
    assert_equal(nil, user.lastname)
    assert_equal('User', user.role)
    assert_equal(true, user.verified?)
    
    # This was good too, but do just minimal checks
    user = User.find_by_email(emails[2])
    assert_equal('good', user.firstname)
    
    # This one wasn't even picked up as an email
    assert_equal(nil, User.find_by_email(emails[3]))
    
    #This is a duplicate, make sure it didn't change old data
    user = User.find_by_email(emails[4])
    assert_equal('Max', user.firstname)
    assert_equal('Dunn', user.lastname)
    assert_equal('User', user.role)    
    
    # Check the emails
    assert_equal(2, ActionMailer::Base.deliveries.size)
    mail = ActionMailer::Base.deliveries[0]
    assert_equal emails[1], mail.to_addrs[0].to_s
    assert_match('You have been added as a user to the Test Web Site web site.', mail.encoded)
    assert_match("http://#{@request.host}/_action/user/login", mail.encoded)
    assert_match("Your login is: #{emails[1]}", mail.encoded)
    assert_match(/Your password is: \w{8}/, mail.encoded) 
    
    mail = ActionMailer::Base.deliveries[1]
    assert_equal emails[2], mail.to_addrs[0].to_s
    assert_match("Your login is: #{emails[2]}", mail.encoded)
  end
  
  #----------------------------------  
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
    assert_match("You are now logged in to Test Web Site as 'Max Dunn' with role '#{old_user.role}'",@response.body[/<h3>My Account<\/h3>.*?<\/p>/m])
  end
  
  def check_email(firstname, lastname, email, login)
    mail = ActionMailer::Base.deliveries[0]
    assert_equal email, mail.to_addrs[0].to_s
    assert_match(/Dear #{firstname} #{lastname}/, mail.encoded)
    assert_match(/Your login name is: #{login}/, mail.encoded)
    assert_match(/#{@controller.wiki.config[:site_name]}/, mail.encoded)
    assert_match(/http:\/\/#{@request.host}/, mail.encoded)
    mail
  end
  
  def do_change_password(bad_password, bad_email)
    login = "bob"
    email = "bob@test.com"
    password = "atest"  
    new_password = "changed_password"
    too_short_password = "bad"
    
    ActionMailer::Base.deliveries = []
    
    login_user_controller(login, password)
    
    if not bad_password and not bad_email
      post :change_password, :user => {:password => new_password, :password_confirmation => new_password }
      assert_equal 1, ActionMailer::Base.deliveries.size
      check_email('Bob', 'Test' , email, login)
      assert_redirected_to_welcome
    elsif bad_password
      post :change_password, :user => { :password => too_short_password, :password_confirmation => too_short_password }
      assert_response :success
      assert_equal 0, ActionMailer::Base.deliveries.size
      assert_msg_error("Password is too short")
    elsif bad_email
      # This is the test that needs use_transactional_fixtures turned off
      # in order to roll back the database change when the email raises an error
      ActionMailer::Base.inject_one_error = true
      post :change_password, :user => { :password => new_password, :password_confirmation => new_password }
      assert_equal 0, ActionMailer::Base.deliveries.size
      assert_response :success
      assert_template "change_password"
      assert_msg_error("Failed to send email")
    else
      # Invalid test case
      assert false
    end
    
    logout_user_controller
    
    if not bad_password
      login_user_controller(login, new_password)
      post :change_password, :user => { :password => password, :password_confirmation => password }
      logout_user_controller
    end
    
    login_user_controller(login, password)
    get :logout
  end
  
  def do_reset_password(options)
    login = "bob"
    password = "atest"  
    new_password = "anewpassword"
    good_address = "bob@test.com"
    bad_address = "foo@test.com"
    ActionMailer::Base.deliveries = []
    
    if options[:logged_in]
      login_user_controller(login, password)
    end
    
    if not options[:bad_address] and not options[:bad_email]
      post :reset_password, "user" => { "email" => good_address }
      if options[:logged_in]
        assert_no_errors
        assert_equal 0, ActionMailer::Base.deliveries.size
        assert_redirected_to :action => "change_password"
        follow_redirect
        assert_msg_notice('You are currently logged in. You may change your password now.')
        post :change_password, :user => { :password => new_password, :password_confirmation => new_password }
        assert_no_errors
        assert_equal "Your password has been updated, and a reminder emailed to #{good_address}.", flash[:notice]
        assert_redirected_to_welcome
      else
        assert_no_errors
        assert_equal 1, ActionMailer::Base.deliveries.size
        mail = ActionMailer::Base.deliveries[0]
        assert_equal good_address, mail.to_addrs[0].to_s
        id, key = get_id_and_key_from_email
        get :change_password, "id" => id, "key" => key
        assert_no_errors
        assert_template 'change_password'
        
        post :change_password, :user => { :password => new_password, :password_confirmation => new_password }
        assert_no_errors
        assert @response.session[:user]
        assert_redirected_to_welcome
        assert_equal flash[:notice], "Your password has been updated, and a reminder emailed to #{good_address}."
        get :logout
      end
    elsif options[:bad_address]
      post :reset_password, :user => { :email => bad_address }
      assert_msg_error('We could not find a user with the email address foo@test.com.')
      assert_equal 0, ActionMailer::Base.deliveries.size
    elsif options[:bad_email]
      ActionMailer::Base.inject_one_error = true
      post :reset_password, :user => { :email => good_address }
      assert_msg_error('Failed to send email')
      assert_equal 0, ActionMailer::Base.deliveries.size
    else
      # Invalid test case
      assert false
    end
    
    if not options[:bad_address] and not options[:bad_email]
      if options[:logged_in]
        logout_user_controller
      else
        assert_response :success
      end
      login_user_controller("bob", new_password)
    else
      # Okay, make sure the database did not get changed
      if options[:logged_in]
        logout_user_controller
      end
      login_user_controller("bob", "atest")
    end
    
    assert @response.session[:user]
    
    # Put the old settings back
    if not options[:bad_address] and not options[:bad_email]
      post :change_password, "user" => { "password" => "atest", "password_confirmation" => "atest" }
    end
    
    get :logout
  end
  
  def get_id_and_key_from_email
    mail = ActionMailer::Base.deliveries[0]
    mail.encoded =~ /id=(.*?)&key=(.*?)"/
    id = $1.to_i
    key = $2
    return id, key
  end
  
end
