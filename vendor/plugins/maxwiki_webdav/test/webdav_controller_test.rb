require './test/test_helper'
require 'webdav_controller'

# Re-raise errors caught by the controller.
class WebdavController; def rescue_action(e) raise e end; end

class UploadFile < File
  attr_accessor :original_filename, :content_type
end

class WebdavControllerTest < Test::Unit::TestCase
  fixtures :wikis, :system
  
  FILE_NAME = 'Checkout Test.txt'
  NEW_FILE_NAME = 'New File.txt'
  FILE_PATH = "#{WEBDAV_PATH}/#{FILE_NAME}"
  NEW_FILE_PATH = "#{WEBDAV_PATH}/#{NEW_FILE_NAME}"
  LOCK_NAME = 'test@maxdunn.com'
  CONNECTION_ID = 'a09e7b8fd5c859bcb7d8'
  
  def setup
    @controller = WebdavController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end
  
  def test_list
    get :list, :webdav_server => WEBDAV_SERVER + WEBDAV_PATH, :webdav_username => WEBDAV_USERNAME, :webdav_password => WEBDAV_PASSWORD, 
    :webdav_dir => nil, :connection => 'browser'
    assert_no_errors
    assert_tag(:h1, :content => "Directory: #{WEBDAV_PATH}")
    select = assert_select 'td>a[href]', 14
    assert_href("http://local.xythos.com:8080/Users/mdunn@maxwiki.com/Test Dir/Subdirectory/", select[0].to_s)
    assert_includes("/_action/webdav/list", select[1].to_s)
    assert_includes("webdav_dir=%2FUsers%2Fmdunn%40maxwiki.com%2FTest+Dir%2FSubdirectory%2F", select[1].to_s)
    assert_href_includes("/_action/webdav/checkout", select[10].to_s)
    assert_href_includes("path=%2FUsers%2Fmdunn%40maxwiki.com%2FTest+Dir%2FPlain.txt", select[10].to_s)
    assert_href_includes("connection_id=a09e7b8fd5c859bcb7d8", select[10].to_s)
    
    get :update_browser, :webdav_dir => '/Users/mdunn@maxwiki.com/Test Dir/Subdirectory/', :connection => 'browser'
    assert_no_errors
    assert_tag(:h1, :content => "Directory: #{WEBDAV_PATH}/Subdirectory/")
    
    select = assert_select 'td>a[href]', 2
    assert_includes("webdav_dir=%2F", select[1].to_s)
    assert_includes("connection=browse", select[1].to_s)
  end  
  
  def test_search
    get :search, :webdav_server => WEBDAV_SERVER, 
    :webdav_username => WEBDAV_USERNAME, :webdav_password => WEBDAV_PASSWORD, 
    :webdav_dir => '/', :connection => 'search',
    :conditions => "['Type', 'eq', 'Contract']", 
    :properties => "'PropertyName','Type', 'InternalLawyer', 'DateDue'"
    
    assert_no_errors
    
    # Make sure header is correct
    assert_no_tag(:h1)
    
    # Make sure file list is correct
    select = assert_select 'td>a[href]', 9
    assert_href("#{WEBDAV_SERVER}/Users/mdunn@maxwiki.com/MaxWiki/AboutMe.html", select[0].to_s)
    assert_href("#{WEBDAV_SERVER}#{WEBDAV_PATH}/SAP Implementation Course.doc", select[6].to_s)
    
    # Check property header
    select = assert_select 'th', 6
    assert_equal(["Name", "Property Name", "Type", "Internal Lawyer", "Date Due", "Check-out"], select.map {|t| t.children.to_s} )
    
    # Check property values
    select = assert_select 'td', 18
    assert_equal(["Los Angeles",
      "Contract",
      "Joe Internal",
      "2007-06-01T07:00:00Z"], 
    select[7..10].map {|t| t.children.to_s})
  end  
  
  def test_show_bar
    # First show the bar with no saved params, so it will be empty
    get :show_bar
    assert_no_errors
    assert_tag(:div, :attributes => {:class => 'webdav_list'}, :content => "The server string '' is not correct")
    select = assert_select 'input', 4
    assert_includes('value=""',select[0].to_s)
    assert_not_included('value',select[1].to_s)
    assert_not_included('value',select[2].to_s)
    
    # Now save some parameters
    get :browser_connection_info, :connection => 'bar', 
    :webdav_server => WEBDAV_SERVER + WEBDAV_PATH, :webdav_username => WEBDAV_USERNAME, :webdav_password => WEBDAV_PASSWORD
    assert_no_errors
    assert_template('_webdav_browser')
    assert_tag(:h1, :content => "Directory: #{WEBDAV_PATH}")
    
    # Now show the bar again and make sure it has the new parameters but no checkout column
    get :show_bar
    assert_no_errors
    assert_tag(:h1, :content => "Directory: #{WEBDAV_PATH}")
    assert_no_tag(:div, :attributes => {:class => 'webdav_list'}, :content => "The server string '' is not correct")
    select = assert_select 'input', 4
    assert_includes(%Q{value="#{WEBDAV_SERVER}#{WEBDAV_PATH}"},select[0].to_s)
    assert_includes(%Q{value="#{WEBDAV_USERNAME}"},select[1].to_s)
    assert_includes(%Q{value="#{WEBDAV_PASSWORD}"},select[2].to_s)
    
    select = assert_select 'th', 1
    select = assert_select 'td>a[href]', 6
    assert_href("http://local.xythos.com:8080/Users/mdunn@maxwiki.com/Test Dir/Subdirectory/", select[0].to_s)
    assert_includes("/_action/webdav/update_browser", select[1].to_s)
    assert_includes("webdav_dir=%2FUsers%2Fmdunn%40maxwiki.com%2FTest+Dir%2FSubdirectory%2F", select[1].to_s)
    assert_href("http://local.xythos.com:8080/Users/mdunn@maxwiki.com/Test Dir/Plain.txt", select[4].to_s)
    assert_href("http://local.xythos.com:8080/Users/mdunn@maxwiki.com/Test Dir/SAP Implementation Course.doc", select[5].to_s)
  end
  
  def test_show_upload
    # First show the upload form with no saved params, so it will be empty
    get :show_upload
    assert_no_errors
    select = assert_select 'input', 5
    assert_includes('value=""',select[0].to_s)
    assert_not_included('value',select[1].to_s)
    assert_not_included('value',select[2].to_s)
    
    # Now save some parameters with a fake upload
    get :upload, :connection => 'upload', :upload_id => 1,
    :webdav_server => WEBDAV_SERVER + WEBDAV_PATH, :webdav_username => WEBDAV_USERNAME, :webdav_password => WEBDAV_PASSWORD
    assert_no_errors
    
    # Now show the upload again and make sure it has the new parameters
    get :show_upload
    assert_no_errors
    select = assert_select 'input', 5
    assert_includes(%Q{value="#{WEBDAV_SERVER}#{WEBDAV_PATH}"},select[0].to_s)
    assert_includes(%Q{value="#{WEBDAV_USERNAME}"},select[1].to_s)
    assert_includes(%Q{value="#{WEBDAV_PASSWORD}"},select[2].to_s)
  end
  
  def test_upload
    # Make sure file is unlocked to start off
    unlock_file(FILE_PATH)
    
    # Normal upload, no login
    upload(FILE_NAME)
    assert_no_errors
    assert_tag(:tag => 'script', :content => "#{FILE_NAME} uploaded.")
    
    # Login, lock file and upload again to make sure it sends If header with lock token
    login_editor
    lock_file(FILE_PATH, LOCK_NAME)
    
    upload(FILE_NAME)
    assert_no_errors
    assert_tag(:tag => 'script', :content => "#{FILE_NAME} uploaded.")
    
    # Lock the file as someone else, and make sure upload is rejected
    unlock_file(FILE_PATH)
    lock_file(FILE_PATH, 'Other Person')
    
    upload(FILE_NAME)
    assert_no_errors
    assert_tag(:tag => 'script', :content => "File is locked by Other Person")
    
    # Cleanup
    unlock_file(FILE_PATH)
  end  
  
  def test_new_upload
    # Make sure file is not there
    delete_file(NEW_FILE_PATH)
    
    # Upload a new file
    upload(NEW_FILE_NAME)
    assert_no_errors
    assert_tag(:tag => 'script', :content => "#{NEW_FILE_NAME} uploaded.")
    
    # Cleanup
    delete_file(NEW_FILE_PATH)
  end
  
  # These tests just make sure that the lock icon and link in the list is correct  
  def test_lock
    login_editor
    
    # Make sure file is unlocked to start off
    webdav = Webdav.new(WEBDAV_SERVER, WEBDAV_USERNAME, WEBDAV_PASSWORD, LOCK_NAME)
    token = webdav.get_lock_token(FILE_PATH, :any_owner)
    webdav.unlock(FILE_PATH, token) unless webdav.error?
    assert_list_lock(FILE_PATH, 'checkout', 'lock.gif')
    
    # Lock the file and make sure list has the correct lock action and icon
    webdav.lock(FILE_PATH)
    assert(!webdav.error?, webdav.error_msg)
    assert_list_lock(FILE_PATH, 'checkin', 'lock_green.gif')
    
    # unlock    
    token = webdav.get_lock_token(FILE_PATH)
    webdav.unlock(FILE_PATH, token) unless webdav.error?
    assert(!webdav.error?, webdav.error_msg)
    assert_list_lock(FILE_PATH, 'checkout', 'lock.gif')
    
    # Lock the file as someone else
    webdav.lock_owner = 'Other Person Lock'
    webdav.lock(FILE_PATH)
    assert(!webdav.error?, webdav.error_msg)
    assert_list_lock(FILE_PATH, 'locked', 'lock_red.gif')
    
    # Cleanup
    token = webdav.get_lock_token(FILE_PATH, :any_owner)
    webdav.unlock(FILE_PATH, token)
  end
  
  # These tests check the checkout and checkin process
  def test_checkout
    other_lock_name = 'Other Person'
    
    login_editor
    
    # Make sure file is unlocked to start off and that the connection_id params are saved
    unlock_file(FILE_PATH)
    assert_list_lock(FILE_PATH, 'checkout', 'lock.gif')
    
    get :checkout, :connection_id => CONNECTION_ID, :path => FILE_PATH
    assert_no_errors
    assert_tag(:tag => 'a', :content => "#{File.basename(FILE_PATH)}", 
    :ancestor => {:tag => 'div', :attributes => {:id => "middle_column"}})
    
    get :checkin, :connection_id => CONNECTION_ID, :path => FILE_PATH
    assert_no_errors
    assert_tag(:tag => 'p', :content => "Checking in #{File.basename(FILE_PATH)}", 
    :ancestor => {:tag => 'div', :attributes => {:id => "middle_column"}})
    select = assert_select 'input'
    assert_includes(%Q{value="#{WEBDAV_SERVER}#{WEBDAV_PATH}"},select[0].to_s)
    assert_includes(%Q{value="#{WEBDAV_USERNAME}"},select[1].to_s)
    assert_includes(%Q{value="#{WEBDAV_PASSWORD}"},select[2].to_s)
    
    # Unlock the file
    get :unlock, :connection_id => CONNECTION_ID, :path => FILE_PATH
    assert_no_errors
    
    # Lock the file as someone else
    lock_file(FILE_PATH, other_lock_name)
    
    get :locked, :connection_id => CONNECTION_ID, :path => FILE_PATH
    assert_no_errors
    assert_tag(:tag => 'p', :content => "is locked by #{other_lock_name}", 
    :ancestor => {:tag => 'div', :attributes => {:id => "middle_column"}})
    
    # Cleanup
    unlock_file(FILE_PATH)
  end
  
  #-------------
  private
  
  def upload(filename)
    file = UploadFile.new(RAILS_ROOT + "/test/fixtures/#{filename}")
    file.original_filename = filename
    
    post :upload, :connection => 'upload', 
    :webdav_server => WEBDAV_SERVER + WEBDAV_PATH, :webdav_username => WEBDAV_USERNAME, :webdav_password => WEBDAV_PASSWORD,
    :upload => {:file => file}, :upload_id => 1
    
    # Do this so finish_upload_status in upload_progress.rb can be called again. 
    # Otherwise, the second time upload is called, it will report "Can't find templage 'upload'"
    @controller.instance_variable_set(:@rendered_finish_upload_status, false)
  end
  
  def assert_list_lock(file_path, action, icon)
    get :list, :webdav_server => WEBDAV_SERVER + WEBDAV_PATH, :webdav_username => WEBDAV_USERNAME, :webdav_password => WEBDAV_PASSWORD, 
    :webdav_dir => nil, :connection => 'browser'
    assert_no_errors    
    select = assert_select 'td>a[href]', 14
    assert_href("#{WEBDAV_SERVER}#{file_path}", select[5].to_s)
    assert_href("#{WEBDAV_SERVER}#{file_path}", select[6].to_s)
    assert_includes("/_action/webdav/#{action}", select[7].to_s)
    assert_href_includes("path=#{CGI.escape(file_path)}", select[7].to_s)
    assert_includes(icon, select[7].to_s)
  end
  
  def assert_href(baseline, atag)
    assert_equal(baseline, atag.match(/href="(.*?)"/)[1])
  end
  
  def assert_href_includes(partial_baseline, atag)
    compare_str = atag.match(/href="(.*?)"/)[1]
    assert_includes(partial_baseline, compare_str)
  end
  
  def lock_file(file_path, lock_name)
    webdav = Webdav.new(WEBDAV_SERVER, WEBDAV_USERNAME, WEBDAV_PASSWORD, lock_name)
    webdav.lock(file_path) unless webdav.error?
  end
  
  def unlock_file(file_path)
    webdav = Webdav.new(WEBDAV_SERVER, WEBDAV_USERNAME, WEBDAV_PASSWORD)
    token = webdav.get_lock_token(file_path, :any_owner)
    webdav.unlock(file_path, token) unless webdav.error?
  end
  
  def delete_file(file_path)
    webdav = Webdav.new(WEBDAV_SERVER, WEBDAV_USERNAME, WEBDAV_PASSWORD)
    webdav.delete(file_path) unless webdav.error?
  end
  
end
