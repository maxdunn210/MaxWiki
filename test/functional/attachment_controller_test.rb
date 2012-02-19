require File.dirname(__FILE__) + '/../test_helper'
require 'attachment_controller'

# Re-raise errors caught by the controller.
class AttachmentController < ApplicationController; def rescue_action(e) raise e end; end

# the class Tempfile is used by Rails for uploaded files; unfortunately, it's not exactly 
# Tempfile... so here we add some methods to make Tempfile look like the Tempfile that's
# seen by the controller
class Tempfile
  attr_accessor :original_filename  
  def read
      "This is a test file attachment"
  end
end

class AttachmentControllerTest < Test::Unit::TestCase
  fixtures :events, :teams, :lookups, :wikis, :system, :revisions, :pages, :wiki_references
  
  def setup
    @controller = AttachmentController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
    MY_CONFIG[:file_upload_root] = File.expand_path(File.join(RAILS_ROOT, 'test', 'fixtures'))
    MY_CONFIG[:file_upload_top] = '/attachments'
    MY_CONFIG[:file_upload_directory] = '/%w/%p'
  end
  
  def test_show
    # there should be 2 attachments in the fixtures/attachments/TestPage directory
    login_editor
    get :show, :page_name => 'TestPage'
    assert_response :success
    assert_file_count(2)
  end
  
  def test_upload  
    login_editor
    cleanup_temp # Make sure nothing leftover
    
    # create tempfile object (see added method definition at top of this file)
    sio = Tempfile.new(nil)
    sio.original_filename = "test.txt"
    post :file_upload, :page_name => 'TestPageEmpty', :stored_file => {:stored_file=>sio}
    assert_response :success
    
    # verify that we've loaded this file
    get :show, :page_name => 'TestPageEmpty'
    assert_response :success
    assert_file_count(1)
    
    cleanup_temp
  end
  
  def test_delete
    login_editor
    cleanup_temp # make sure the upload target directory is empty
    
    # create an attachment
    dir = MY_CONFIG[:file_upload_root] + '/attachments/maxwiki/TestPageEmpty'
    File.open(dir+'/'+'to_be_deleted','w') do |f|
      f.write("this file should not exist after the test!!!")
    end
    
    # verify that the attachment is here
    get :show, :page_name => 'TestPageEmpty'
    assert_response :success
    assert_file_count(1)
    
    # delete the file
    post :delete, :page_name => 'TestPageEmpty', :filename => 'to_be_deleted'
    assert_response :success    
    
    # verify that there is no attachment anymore
    get :show, :page_name => 'TestPageEmpty'
    assert_response :success
    assert_file_count(0)
  end
  
  def test_security_not_logged_in
    # create tempfile object (see added method definition at top of this file)
    sio = Tempfile.new(nil)
    sio.original_filename = "test.txt"
    
    #Make sure that we need at least an editor role to upload, delete and display
    post :file_upload, :page_name => 'TestPageEmpty', :stored_file => {:stored_file=>sio}
    assert_access_denied
    post :delete, :page_name => 'TestPageEmpty', :filename => 'to_be_deleted'
    assert_access_denied
    get :show, :page_name => 'TestPage'
    assert_access_denied
  end
  
  def test_security_upload
    # create tempfile object (see added method definition at top of this file)
    sio = Tempfile.new(nil)
    sio.original_filename = "test.txt"
    
    login_editor    
    
    assert_raise(SecurityError) {
      post :file_upload, :page_name => '..', :stored_file => {:stored_file=>sio} 
    }
    
    sio.original_filename = "../test.txt"
    assert_raise(SecurityError) {
      post :file_upload, :page_name => 'TestPageEmpty', :stored_file => {:stored_file=>sio} 
    }
  end
  
  def test_security_delete
    login_editor    
    
    assert_raise(SecurityError) {
      post :delete, :page_name => '../TestPageEmpty', :filename => 'to_be_deleted'
    }
    
    assert_raise(SecurityError) {
      post :delete, :page_name => 'TestPageEmpty', :filename => '../to_be_deleted'
    }
  end
  
  def test_security_show
    login_editor    
    
    # These variants of ".." don't get expanded out but are interpreted as a page name so it creates a directory
    ['%2E%2E', '%u002E%u002E', '%252E%252E']. each do |page_name|
      get :show, :page_name => page_name
      assert_response :success
      assert_file_count(0)
      path = File.join(MY_CONFIG[:file_upload_root], MY_CONFIG[:file_upload_top], "maxwiki/#{page_name}")
      assert(File.exists?(path), "Doesn't exist: #{path}")
      assert(Dir.rmdir(path), "Can't remove: #{path}")
    end
    
    # These variants of '..' do get expanded so they should throw an exception
    # The "\000." variant gets expanded by Ruby when it has the double brackets 
    ["..","\000.\000.","\376\377\000.\000." ].each do |page_name|
      assert_raise(SecurityError) {
        get :show, :page_name => page_name
      }
    end
  end    
  
  #------------
  private
  
  def cleanup_temp
    cleanup(File.join(MY_CONFIG[:file_upload_root], MY_CONFIG[:file_upload_top], 'maxwiki/TestPageEmpty'))
  end
  
  def cleanup(dir)
    Dir.foreach(dir) do |filename| 
      File.delete(dir+'/'+filename) unless filename.starts_with?('.')
    end
  end
  
  def assert_file_count(num)
    assert_select "div#file_list" do
      assert_select "table" do
        assert_select "tr", :count => num + 1  # Header is always present
      end
    end  
  end 
  
  def assert_access_denied
    assert_redirected_to :controller => 'user', :action => 'login'  
  end
  
  
end
