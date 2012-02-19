require './test/test_helper'

class WebdavTest < Test::Unit::TestCase
  
  TEST_DIR = '/Users/mdunn@maxwiki.com/Test Dir'
  TEST_PATH = TEST_DIR + '/Plain.txt'
  
  def test_new
    webdav = Webdav.new('http://local.xythos.com/')
    assert(!webdav.error?, 'Server string error')
    
    webdav = Webdav.new('local@xythos.com')
    assert(webdav.error?, 'Server string error')
    assert_equal("The server string 'local@xythos.com' is not correct", webdav.error_msg)
  end  
  
  def test_propfind
    correct_names = ["Checkout Test.txt",
      "Plain.txt",
      "SAP Implementation Course.doc",
      "Subdirectory",
      "Test Dir",
      "back.gif"] 
    
    names = propfind_names(WEBDAV_PATH)
    assert_equal(correct_names, names)
  end  
  
  def test_get
    webdav = connect
    webdav.get(TEST_PATH)
    assert(!webdav.error?, webdav.error_msg)
    assert_includes('This is a test document.', webdav.result.body);
  end
  
  def test_put_delete  
    webdav = connect
    test_path = '/Users/mdunn@maxwiki.com/Test.txt'
    content = "This is a test at #{Time.now}"
    webdav.put(test_path, content)
    assert(!webdav.error?, webdav.error_msg)
    
    webdav.get(test_path)
    assert(!webdav.error?, webdav.error_msg)
    assert_equal(content, webdav.result.body);
    
    webdav.delete(test_path)
    assert(!webdav.error?, webdav.error_msg)
  end
  
  def test_list
    webdav = connect
    
    # Make sure no .. entry when listing top directory
    webdav.dir_list('/')
    assert(!webdav.error?, webdav.error_msg)
    assert_equal(['Users'], webdav.list.map {|e| e.name})
    
    webdav.dir_list(TEST_DIR)
    assert(!webdav.error?, webdav.error_msg)
    assert_equal([".. (Up one directory)", 
      "Subdirectory",
      "back.gif",
      "Checkout Test.txt",
      "Plain.txt",
      "SAP Implementation Course.doc"], 
    webdav.list.map {|e| e.name})
  end
  
  def test_list_no_auth
    webdav = Webdav.new(WEBDAV_SERVER)
    
    webdav.dir_list(TEST_DIR)
    assert(!webdav.error?, webdav.error_msg)
    assert_equal([".. (Up one directory)", 
      "Subdirectory",
      "back.gif",
      "Checkout Test.txt",
      "Plain.txt",
      "SAP Implementation Course.doc"], 
    webdav.list.map {|e| e.name})
  end
  
  def test_lock_unlock
    lock_owner = 'Max Dunn'
    webdav = connect(nil, lock_owner)
    
    # Make sure the file is unlocked to start off
    token = webdav.get_lock_token(TEST_PATH)
    webdav.unlock(TEST_PATH, token)
    
    # Lock first time
    webdav.lock(TEST_PATH)
    assert(!webdav.error?, webdav.error_msg)
    
    # Lock again
    webdav.lock(TEST_PATH)
    assert_equal('Locked', webdav.error_msg)
    
    # Try unlocking with bad token
    webdav.unlock(TEST_PATH, 'bad_token')
    assert_equal('Precondition Failed', webdav.error_msg)
    
    # Try getting lock token with bad owner
    webdav.lock_owner = "Bad lock owner"
    token = webdav.get_lock_token(TEST_PATH)
    assert_equal('File is locked by Max Dunn', webdav.error_msg)
    
    # Get lock token
    webdav.lock_owner = lock_owner
    token = webdav.get_lock_token(TEST_PATH)
    assert(token, 'Lock token not found')
    assert(!webdav.error?, webdav.error_msg)
    
    # Unlock
    webdav.unlock(TEST_PATH, token)
    assert(!webdav.error?, webdav.error_msg)
    
    # Try to unlock again
    webdav.unlock(TEST_PATH, token)
    assert_equal('Precondition Failed', webdav.error_msg)
    
    # Try to get lock token
    token = webdav.get_lock_token(TEST_PATH)
    assert(!token, 'Lock token was found on unlocked file')
    assert_equal('File is not locked', webdav.error_msg)
  end
  
  def test_parse_path
    path = Webdav.parse_path('http://local.xythos.com:8080/file.txt')
    assert_equal('/file.txt',path)
    
    path = Webdav.parse_path('http://local.xythos.com:8080/dir/')
    assert_equal('/dir/',path)
    
    path = Webdav.parse_path('http://local.xythos.com/dir with space/file.txt')
    assert_equal('/dir with space/file.txt',path)
    
    path = Webdav.parse_path('http://local.xythos.com/file&with_weird-characters+in.it')
    assert_equal('/file&with_weird-characters+in.it',path)
    
    path = Webdav.parse_path('http://local.xythos.com/')
    assert_equal('/',path)
    
    path = Webdav.parse_path('http://local.xythos.com')
    assert_equal('/',path)
    
    path = Webdav.parse_path('http://bad@.xythos.com/file.txt')
    assert_equal('',path)
  end
  
  def test_parse_server
    server = Webdav.parse_server('http://local.xythos.com:8080/file.txt')
    assert_equal('http://local.xythos.com:8080',server)
    
    server = Webdav.parse_server('http://local.xythos.com:80/file.txt')
    assert_equal('http://local.xythos.com',server)
    
    server = Webdav.parse_server('http://local.xythos.com/file.txt')
    assert_equal('http://local.xythos.com',server)
    
    server = Webdav.parse_server('http://local.xythos.com')
    assert_equal('http://local.xythos.com',server)
    
    server = Webdav.parse_server('http://username:password@local.xythos.com')
    assert_equal('http://local.xythos.com',server)
    
    server = Webdav.parse_server('local.xythos.com')
    assert_equal('http://local.xythos.com',server)
    
    server = Webdav.parse_server('http://bad@.local.xythos.com')
    assert_equal('',server)
  end
  
  def test_search
    conditions = [[:Type, :eq, 'Contract']]
    columns = nil
    webdav = connect
    webdav.search('/', conditions, columns)
    assert(!webdav.error?, webdav.error_msg)
    
    hrefs = webdav.result_xml.elements.to_a("D:multistatus/D:response/D:href").map {|e| e.text}
    assert_equal(["http://local.xythos.com:8080/Users/mdunn%40maxwiki.com/LDAP_Understanding.pdf",
      "http://local.xythos.com:8080/Users/mdunn%40maxwiki.com/Test%20Dir/SAP%20Implementation%20Course.doc",
      "http://local.xythos.com:8080/Users/mdunn%40maxwiki.com/MaxWiki/AboutMe.html"], hrefs)
  end
  
  def test_search_list
    webdav = connect(root_path = '', lock_owner = nil, searching = true)
    webdav.search_list(WEBDAV_PATH)
    assert(!webdav.error?, webdav.error_msg)
    
    assert_equal(["http://local.xythos.com:8080/Users/mdunn@maxwiki.com/Test Dir/Subdirectory/",
     "http://local.xythos.com:8080/Users/mdunn@maxwiki.com/Test Dir/back.gif",
     "http://local.xythos.com:8080/Users/mdunn@maxwiki.com/Test Dir/Checkout Test.txt",
     "http://local.xythos.com:8080/Users/mdunn@maxwiki.com/Test Dir/Plain.txt",
     "http://local.xythos.com:8080/Users/mdunn@maxwiki.com/Test Dir/SAP Implementation Course.doc"], 
    webdav.list.map {|e| e.href})
    
    conditions = [[:Type, :eq, 'Contract']]
    columns = nil
    webdav.search_list('/', conditions, columns)
    assert(!webdav.error?, webdav.error_msg)
    
    assert_equal(["http://local.xythos.com:8080/Users/mdunn@maxwiki.com/MaxWiki/AboutMe.html",
     "http://local.xythos.com:8080/Users/mdunn@maxwiki.com/LDAP_Understanding.pdf", 
     "http://local.xythos.com:8080/Users/mdunn@maxwiki.com/Test Dir/SAP Implementation Course.doc"], 
    webdav.list.map {|e| e.href})
  end
  
  def test_search_columns
    conditions = [[:Type, :eq, 'Contract']]
    columns = ['PropertyName','Type', 'InternalLawyer', 'DateDue']
    webdav = connect(root_path = '', lock_owner = nil, searching = true)
    webdav.search_list('/', conditions, columns)
    assert(!webdav.error?, webdav.error_msg)
    
    assert_equal({"PropertyName"=>"Los Angeles",
     "InternalLawyer"=>"Joe Internal",
     "Type"=>"Contract",
     "DateDue"=>"2007-06-01T07:00:00Z"}, 
    webdav.list[1].properties)
  end
  
  #------------------
  private
  
  def propfind_names(dir)  
    webdav = connect
    webdav.propfind(dir)
    assert(!webdav.error?, webdav.error_msg)
    names = webdav.result_xml.elements.to_a("D:multistatus/D:response/D:propstat/D:prop/D:displayname").map do |e| 
      e.text unless e.text.starts_with?('.')
    end
    names.compact.sort
  end 
  
  def connect(root_path = '', lock_owner = nil, searching = false)
    options = {}
    options[:no_up_dir] = true if searching
    Webdav.new(WEBDAV_SERVER + "/#{root_path}/".squeeze('/'), WEBDAV_USERNAME, WEBDAV_PASSWORD, lock_owner, options)
  end
  
end
