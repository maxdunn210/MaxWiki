require File.dirname(__FILE__) + '/../test_helper'
require 'fileutils'

TEST_PAGE = 'HTML+Sample'
TEST_PAGE_LINK = 'html_sample'
HOST_NAME = 'www.cachetest.com'

if ACTIVE_PLUGINS.include?("maxwiki_multihost")
  FILE_STORE_PATH = "#{RAILS_ROOT}/public/cache/#{HOST_NAME}" 
else
  FILE_STORE_PATH = "#{RAILS_ROOT}/public/cache" 
end

# Note: 
#   ActionController::Base.perform_caching = true 
# should be on in the test environment for these tests to run

class CacheTest < ActionController::IntegrationTest
  fixtures :events, :teams, :lookups, :wikis, :system, :revisions, :pages, :wiki_references, :adults
  
  def setup
    super  
    setup_host(HOST_NAME)
    FileUtils.rm_rf(FILE_STORE_PATH)
  end
  
  def test_cache
    cache_page(TEST_PAGE_LINK)
  end
  
  def test_cache_blank
    get '/homepage'
    assert_no_errors
    assert_page_cached('index')
  end
  
  # Now pass it the page name but make sure it caches by the page link
  def test_cache_link
    get '/' + TEST_PAGE
    assert_redirected_to :link => TEST_PAGE_LINK
    
    follow_redirect!
    assert_no_errors
    assert_page_cached(TEST_PAGE_LINK)
  end
  
  def test_no_cache
    page = Page.find_by_link(TEST_PAGE_LINK)
    page.current_revision.content << "\n<%= no_cache %>"
    page.current_revision.save!
    
    get '/' + TEST_PAGE_LINK
    assert_no_errors
    assert_page_not_cached(TEST_PAGE_LINK)
  end
  
  # When renaming just the page name, and not the link, the file will still be cached with the old link
  def test_rename_page_name
    cache_page(TEST_PAGE_LINK)
    
    login_editor_integrated
    new_name = 'Renamed Page'
    new_name_link = 'renamed_page'
    content = 'This is a renamed page'
    
    post url_for(:controller => 'wiki', :action => 'save', :link => TEST_PAGE_LINK, :author => 'Test Author', :content => content, :page_name => new_name)
    assert_no_errors 
    follow_redirect!
    assert_no_errors
    assert_page_cached(TEST_PAGE_LINK)    
    assert_page_not_cached(new_name_link)    
  end
  
  def test_clear_one
    cache_page(TEST_PAGE_LINK)

    @integration_session.headers['user-agent'] = 'Test'    

    login_editor_integrated
    post url_for(:controller => 'wiki', :action => 'save', :link => TEST_PAGE_LINK, :author => 'Test Author', :content => 'Test content')
    assert_no_errors
    assert_page_not_cached(TEST_PAGE_LINK)
  end
  
  def test_clear_related
    parent_link = 'teams'
    parent_name = 'Teams'
    child_link = 'Minors+Padres'
    left_link = 'teams_left'
    linked_link = 'minors_giants_left'
    cache_page(parent_link)
    cache_page(child_link)
    cache_page(left_link)
    cache_page(linked_link)
  
    login_editor_integrated  
    post url_for(:controller => 'wiki', :action => 'save', :link => child_link, :author => 'Cache Author', :content => 'Cache test', :page_parent => parent_name)
    assert_no_errors
    assert_page_not_cached(child_link)
    assert_page_not_cached(parent_link)
    assert_page_not_cached(left_link)
    assert_page_not_cached(linked_link)
  end
  
  def test_blog_paging
    blog_name = 'Blog'
    blog_link = 'blog'
    setup_blog(blog_name)
    MY_CONFIG[:blog_posts_per_page] = 2
    
    get '/blog__page_2'
    assert_no_errors
    assert_page_cached(blog_link + '__page_2')    
    assert_page_not_cached(blog_link)    

    get '/blog'
    assert_no_errors
    assert_page_cached(blog_link)    
  end
  
  def test_clear_related_blog
    blog_name = 'Blog'
    blog_link = 'blog'
    blog_2_link = 'blog__page_2'
    other_link = 'teams'
    setup_blog(blog_name)
    MY_CONFIG[:blog_posts_per_page] = 2
    cache_page(blog_link)
    cache_page(blog_2_link)
    cache_page(other_link)

    login_editor_integrated
    post url_for(:controller => 'wiki', :action => 'save', :link => blog_link, :author => 'Cache Author', :content => 'Cache test')
    assert_no_errors
    assert_page_not_cached(blog_link)
    assert_page_not_cached(blog_2_link)
    assert_page_cached(other_link)
  end  

  #------------------  
  private
  def assert_page_cached(link, message = "#{link} should have been cached")
    assert page_cached?(link), message
  end
  
  def assert_page_not_cached(link, message = "#{link} shouldn't have been cached")
    assert !page_cached?(link), message
  end
  
  def page_cached?(link)
    File.exist? "#{FILE_STORE_PATH}/#{link}.html"
  end
  
  def cache_page(name)
    get url_for(:controller => 'wiki', :action => 'show', :link => name)
    assert_no_errors
    assert_page_cached(name)
  end
end  