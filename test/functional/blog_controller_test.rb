require File.dirname(__FILE__) + '/../test_helper'
require 'blog_controller'

# Re-raise errors caught by the controller.
class BlogController; def rescue_action(e) raise e end; end

class BlogControllerTest < Test::Unit::TestCase
  fixtures :wikis, :system, :revisions, :pages, :wiki_references
  
  def setup
    @controller = BlogController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end
  
  BLOG_NAME = 'Blog'
  BLOG_LINK = 'blog'
  
  def test_show
    setup_blog(BLOG_NAME)
    MY_CONFIG[:blog_posts_per_page] = 4

    get :show, :parent => BLOG_LINK
    assert_no_errors
  
    select = assert_select 'h2>a[href]'
    assert_equal(["Blog Entry 4", "Blog Entry 3", "Blog Entry 2", "Blog Entry 1"], select.map {|s| s.children.to_s})    
  end
      
  def test_show_page_2
    setup_blog(BLOG_NAME)
    MY_CONFIG[:blog_posts_per_page] = 2

    get :show, :parent => BLOG_LINK, :page => 2
    assert_no_errors
    select = assert_select 'h2>a[href]'
    assert_equal(["Blog Entry 2", "Blog Entry 1"], select.map {|s| s.children.to_s})    
  end
  
  def test_summary
    search_text = "So this is truncated after this line</p>\n<p><a href='/blog_entry_1'>Read more...</a></p>\n\n  <p>&nbsp;</p>" 
    setup_blog(BLOG_NAME)
    MY_CONFIG[:blog_posts_per_page] = 4

    get :show, :parent => BLOG_LINK
    assert_no_errors
    assert_includes(search_text)
  end
  
end  