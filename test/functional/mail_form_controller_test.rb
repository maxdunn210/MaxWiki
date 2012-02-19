require File.dirname(__FILE__) + '/../test_helper'
require 'mail_form_controller'

# Re-raise errors caught by the controller.
class MailFormController; def rescue_action(e) raise e end; end

class MailFormControllerTest < Test::Unit::TestCase
  fixtures :system, :wikis
  
  def setup
    @controller = MailFormController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end
  
  def test_send
    ActionMailer::Base.deliveries = []
    answer = "\n\n  <b>interest:</b> High<br />\n\n  <b>name:</b> Max Dunn<br />\n\n"
    
    # Post the survey
    post :send_form, :name => 'Max Dunn', :interest => 'High'
    assert_no_errors
    
    # Check the response page   
    select = assert_select 'p'
    assert_equal('Thank you for your response. The information sent was:', select[0].children.to_s)
    assert_equal(answer, select[1].children.to_s)
    
    # Check the email 
    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = ActionMailer::Base.deliveries[0]
    assert_equal('info@maxwiki.com', mail.to_addrs[0].to_s)
    
    root = HTML::Document.new(mail.body).root
    select = assert_select(root, 'p')
    assert_equal('Information received:', select[0].children.to_s)
    assert_equal(answer, select[1].children.to_s)
  end
  
  def test_multiple_email_addresses
    ActionMailer::Base.deliveries = []
    email1 = 'test1@maxtest.com'
    email2 = 'test2@testmax.com'
    @wiki.config[:signup_cc_to] = "#{email1}, #{email2}"   
    @wiki.save!    
  
    post :send_form, :name => 'Max Dunn', :interest => 'High'
    assert_no_errors
    
    # The test delivery doesn't send two emails so just check the addresses
    mail = ActionMailer::Base.deliveries[0]
    assert_equal([email1, email2], mail.to_addrs.map {|a| a.to_s}.sort)
    assert_equal(["info@maxwiki.com"], mail.from_addrs.map {|a| a.to_s}.sort)    
  end

  def test_email_to
    ActionMailer::Base.deliveries = []
    email1 = 'test1@maxwiki.com'
    email2 = 'test2@testmax.com'
  
    post :send_form, :name => 'Max Dunn', :interest => 'High', :email_to => "#{email1}, #{email2}"
    assert_no_errors
    
    # The test delivery doesn't send two emails so just check the addresses
    mail = ActionMailer::Base.deliveries[0]
    assert_equal([email1], mail.to_addrs.map {|a| a.to_s}.sort)
  end
end
