require File.expand_path(File.dirname(__FILE__) + '/../test/test_helper')
require 'maxwiki_include'

class MaxwikiIncludeTest < Test::Unit::TestCase
  
  FileUtils.rm_rf(Dir.glob(TEMP_DIR + '*'))
  
  def setup
    super
    ActionController::Base.page_cache_directory = TEMP_DIR
  end
  
  def test_txt
    include_and_compare_file('Log.txt')
  end
  
  def test_images
    result = include_uri('image.gif')
    assert_equal("<img src=\"image.gif\" alt=\"image\" />", result)
    
    result = include_uri('image.png')
    assert_equal("<img src=\"image.png\" alt=\"image\" />", result)
    
    result = include_uri('image.jpg')
    assert_equal("<img src=\"image.jpg\" alt=\"image\" />", result)
    
    result = include_uri('image.jpeg')
    assert_equal("<img src=\"image.jpeg\" alt=\"image\" />", result)
    
    result = include_uri('image.tif')
    assert_equal("<img src=\"image.tif\" alt=\"image\" />", result)
    
    result = include_uri('image.tiff')
    assert_equal("<img src=\"image.tiff\" alt=\"image\" />", result)
    
    result = include_uri('image.bmp')
    assert_equal("<img src=\"image.bmp\" alt=\"image\" />", result)
  end
  
  def test_doc
    include_and_compare_uri('http://demo.xythos.com/Users/bkeller/MaxWiki/eHealth%20Xpo%20Summary%20061605.doc', 'bkeller', 'welcome')
  end
  
  def test_xls
    include_and_compare_uri('http://demo.xythos.com/Users/bkeller/MaxWiki/BudgetWorksheet05-06.xls', 'bkeller', 'welcome')
  end
  
  def test_html
    include_and_compare_uri('http://demo.xythos.com/Users/bkeller/MaxWiki/Resume.html', 'bkeller', 'welcome')
  end
  
  def test_ppt
    include_and_compare_uri('http://demo.xythos.com/Users/bkeller/MaxWiki/Opening.ppt', 'bkeller', 'welcome')
  end
  
  def test_pdf
    include_and_compare_uri('http://demo.xythos.com/Users/bkeller/MaxWiki/eScripSign-upContest%20-%20How%20To%20%26%20Entry%20Form%20to%20Share%20100706.pdf', 'bkeller', 'welcome')
  end
  
    def test_key
    include_and_compare_uri('http://demo.xythos.com/Users/bkeller/MaxWiki/MaxWiki_BUSD.key.zip', 'bkeller', 'welcome')
  end
  
  def test_cant_include
    result = include_uri('program.exe')
    assert_equal("<p>Unknown type for 'program.exe'</p>\n", result)
  end
  
  def test_force_type
    result = include_uri('image', nil,nil, 'gif')
    assert_equal("<img src=\"image\" alt=\"image\" />", result)
  end
  
  def test_override_type
    result = include_uri('development.log')
    assert_equal("<p>Unknown type for 'development.log'</p>\n", result)
    
    include_and_compare_file('development.log', 'txt')
  end
  
  def test_doc_not_found
    result = include_uri('http://demo.xythos.com/Users/bkeller/MaxWiki/non_existent.doc', 'bkeller', 'welcome')
    assert_equal("<p>Error retrieving http://demo.xythos.com/Users/bkeller/MaxWiki/non_existent.doc: Not Found</p>\n", result)
  end
  
  def test_bad_auth
    result = include_uri('http://demo.xythos.com/Users/bkeller/MaxWiki/bad_auth.doc', 'bkeller', 'bad_password')
    assert_equal("<p>Error retrieving http://demo.xythos.com/Users/bkeller/MaxWiki/bad_auth.doc: Unauthorized</p>\n", result)
  end
  
  def test_bad_dir
    result = include_uri('http://demo.xythos.com/Users/bkeller/bad_dir/bad_dir.doc', 'bkeller', 'welcome')
    assert_equal("<p>Error retrieving http://demo.xythos.com/Users/bkeller/bad_dir/bad_dir.doc: Not Found</p>\n", result)
  end
  
  def test_bad_domain
    result = include_uri('http://bad.domain.com/file.doc')
    assert_equal("<p>Error retrieving http://bad.domain.com/file.doc: Error getaddrinfo: No address associated with nodename accessing http://bad.domain.com/file.doc</p>\n", result)
  end
  
  def test_bad_url
    result = include_uri('not_a_url/bad_url.doc')
    assert_equal("<p>The server string 'not_a_url/bad_url.doc' is not correct</p>\n", result)
  end
  
  def test_bad_url2
    result = include_uri('not even close to url')
    assert_equal("<p>The url 'not even close to url' is not correct</p>\n", result)
  end
  
  def test_caching
    # Cache the document
    uri = 'http://demo.xythos.com/Users/bkeller/MaxWiki/eHealth%20Xpo%20Summary%20061605.doc'
    include_and_compare_uri(uri, 'bkeller', 'welcome')
    wiki_file = WikiFile.find_by_source_uri(uri)
    
    # Change the cached document and converted document
    full_cache_path = File.join(TEMP_DIR, wiki_file.cache_path)
    full_converted_path = File.join(TEMP_DIR, wiki_file.converted_path)
    
    cached_text = 'Cached document'
    converted_text = 'Converted document'
    File.open(full_cache_path, 'w') {|f| f.print(cached_text)} 
    File.open(full_converted_path, 'w') {|f| f.print(converted_text)} 
    
    # Now get it again and make sure cached and converted files didn't change
    include_and_compare_uri(uri, 'bkeller', 'welcome')
    assert_equal(converted_text, File.open(full_converted_path) {|f| f.read})
    assert_equal(cached_text, File.open(full_cache_path) {|f| f.read})
    
    # Change the change marker so it will get it again
    wiki_file.update_attribute(:detect_change_marker, 'foo')
    include_and_compare_uri(uri, 'bkeller', 'welcome')
    assert_not_equal(converted_text, File.open(full_converted_path) {|f| f.read})
    assert_not_equal(cached_text, File.open(full_cache_path) {|f| f.read})
  end
  
  def test_cache_clear
    # Cache the document
    uri = 'http://demo.xythos.com/Users/bkeller/MaxWiki/eHealth%20Xpo%20Summary%20061605.doc'
    include_and_compare_uri(uri, 'bkeller', 'welcome')
    wiki_file = WikiFile.find_by_source_uri(uri)
    
    # Delete the cache directory
    FileUtils.rm_rf(Dir.glob(TEMP_DIR + '*'))
    
    # Make sure it can recreate it
    include_and_compare_uri(uri, 'bkeller', 'welcome') 
  end
    
  #--------------------
  private
  
  def include_and_compare_file(file_name, conversion_type = nil)
    result = MaxwikiInclude.html(FIXTURE_DIR + file_name, nil, nil, conversion_type)
    temp_path = TEMP_DIR + file_name + '.inc'
    File.open(temp_path, 'w') {|f| f.print(result)} unless File.exists?(temp_path)
    compare(temp_path)
  end  
  
  def include_and_compare_uri(uri, username = nil, password = nil, conversion_type=nil)
    result = include_uri(uri, username, password, conversion_type)
    wiki_file = WikiFile.find_by_source_uri(uri)
    temp_path = TEMP_DIR + wiki_file.file_name + '.inc'
    File.open(temp_path, 'w') {|f| f.print(result)} unless File.exists?(temp_path)
    compare(temp_path)
  end  
  
  def include_uri(uri, username = nil, password = nil, conversion_type=nil)
    MaxwikiInclude.html(uri, username, password, conversion_type, MY_CONFIG[:jooconverter])
  end  
end