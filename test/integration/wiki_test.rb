require File.dirname(__FILE__) + '/../test_helper'

class WikiTest < ActionController::IntegrationTest
  fixtures :system, :wikis, :pages, :revisions, :adults
  
  NEW_PAGE = 'New Page'
  NEW_PAGE_LINK = 'new_page'
  
  def test_home_page  
    get ''
    assert_response(:success)
       
    get 'HomePage'
    assert_response(:redirect)
    assert_redirected_to('')    
    
    get 'index.htm'
    assert_response(:redirect)
    assert_redirected_to('')    
  end
  
  def test_page_redirection
    # Check that the page passed as a link just shows that page and doesn't redirect
    get '/Plus+Page'
    assert_response(:success)
    
    # Test link in wrong case
    get '/plus+page'
    assert_response(:redirect)
    assert_redirected_to('Plus+Page')
    
    # Test encoded space in link name
    get '/Plus%20Page'
    assert_response(:redirect)
    assert_redirected_to('Plus+Page')
  end
  
  def test_encoded_link
    # Test encoded colon in link name
    get '/Minors%3A+Giants'
    assert_no_errors
    
    # Test double encoded colon in link name
    get '/Minors%253A+Giants'
    assert_response(:redirect)
    assert_redirected_to('/Minors%3A+Giants')
  end
  
  def test_new
    login_admin_integrated
    get 'New Page'
  end
  
  # These tests require a redirect, so they needs to be in an integration test  
  def test_edit_new_page
    login_editor_integrated
    get url_for(:controller => 'wiki', :action => 'edit', :link => NEW_PAGE_LINK, :page_name => NEW_PAGE)
    check_redirect_new(NEW_PAGE_LINK)
    assert_edit_new(NEW_PAGE_LINK, NEW_PAGE)
  end
  
  def test_show_new_page
    login_editor_integrated
    get url_for(:controller => 'wiki', :action => 'show', :link => NEW_PAGE_LINK, :page_name => NEW_PAGE)
    check_redirect_new(NEW_PAGE_LINK)
    assert_edit_new(NEW_PAGE_LINK, NEW_PAGE)
  end
  
  # This doesn't do a redirect, but it calls assert_edit_new so it is easier to put it with the rest
  def test_new_page  
    login_editor_integrated
    get url_for(:controller => 'wiki', :action => 'new', :link => NEW_PAGE_LINK, :page_name => NEW_PAGE)
    assert_edit_new(NEW_PAGE_LINK, NEW_PAGE)
  end  
  
  # These tests are in addition to the blog_controller_test and test that 
  # the wiki_controller separates the page name from the page number
  def test_blog_paging
    blog_name = 'Test Blog'
    blog_link = 'test_blog'
    setup_blog(blog_name)
    MY_CONFIG[:blog_posts_per_page] = 2
    
    # Simple test, first page
    get blog_link
    assert_no_errors
    select = assert_select 'h2>a[href]'
    assert_equal(["Blog Entry 4", "Blog Entry 3"], select.map {|s| s.children.to_s})    
    
    # Now get page 2
    get "#{blog_link}__page_2"
    assert_no_errors
    select = assert_select 'h2>a[href]'
    assert_equal(["Blog Entry 2", "Blog Entry 1"], select.map {|s| s.children.to_s})    
  end
  
  # This tests that wiki_controller redirects correctly with the page number when passed a page name (not a link)
  def test_blog_page_redirect
    blog_name = 'Test Blog'
    blog_link = 'test_blog'
    setup_blog(blog_name)
    MY_CONFIG[:blog_posts_per_page] = 2
    
    # Test redirect works for second page
    get "Test+Blog__page_2"
    assert_no_errors
    assert_redirected_to('test_blog__page_2')
  end
  
  # Test that when we show a blog post by itself, the title is not a link and the truncation dashes are removed
  def test_show_post
    search_text = "So this is truncated after this line</p>\n\n<p>Now this is the extended content</p>" 
    setup_blog('Test Blog')
    
    get 'blog_entry_1'
    assert_no_errors
    assert_select('h2>a[href]', false)
    assert_includes(search_text)
  end
  
  #------------------
  private
  
  def check_redirect_new(link)
    assert_redirected_to :action => 'new', :link => link
    follow_redirect!
  end  
  
  def assert_edit_new(link, name)
    assert_edit(link, 'textile')
    assert_tag(:tag => 'input', :attributes => {:id => 'page_name', :value => name})
    assert_tag(:tag => 'input', :attributes => {:id => 'page_link', :value => link})
  end
  
end
