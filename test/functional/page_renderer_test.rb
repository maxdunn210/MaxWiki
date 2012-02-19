require File.dirname(__FILE__) + '/../test_helper'
require 'page_renderer'

# Re-raise errors caught by the controller.
class PageRenderer; def rescue_action(e) raise e end; end

class PageRendererTest < Test::Unit::TestCase
  fixtures :system, :wikis, :pages, :revisions
  
  def setup
    @controller = WikiController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end
  
  def test_render
    page = pages(:textile_sample)
    result = page_render(page.revisions.last)

    result.gsub!("\t", '        ')
    html = File.open('test/fixtures/convert_textile.txt') {|f| f.read}

    name = 'test/fixtures/convert_textile.actual.txt'
    if html != result
      File.open(name, 'w') {|f| f.write(result)}
      assert(false, "Render results differ. See the output in #{name}")
    end
    File.delete(name) rescue nil
  end
  
  def test_references
    page = pages(:textile_sample)
    page_render(page.revisions.last, :update_references => true)
    
    references = WikiReference.find(:all, :conditions => ['page_id = ?', page.id])
    
    includes = references.map {|r| r.link_type == WikiReference::INCLUDED_PAGE ? r.referenced_name : nil}.compact
    assert_equal(['Test Include'], includes)
    
    linked_pages = references.map {|r| r.link_type == WikiReference::LINKED_PAGE ? r.referenced_name : nil}.compact
    assert_equal(["Navigation", "Test"], linked_pages)
    
    wanted_pages = references.map {|r| r.link_type == WikiReference::WANTED_PAGE ? r.referenced_name : nil}.compact
    assert_equal(['Test new page'], wanted_pages)
    
    assert_equal(4, references.size)
  end  
  
  def test_url_for
    page = pages(:test_textile)
    revision = page.revisions.last
    revision.content = '[[Test Page]]'
    render_both(revision, "<p><span class=\"new_page_link\"><a href=\"/Test+Page\">Test Page?</a></span></p>")
  end
  
  def test_url_for_port
    ActionController::UrlWriter.default_url_options[:host] = 'test.host:3000'    
    page = pages(:test_textile)
    revision = page.revisions.last
    revision.content = '[[HomePage]]'
    render_both(revision, "<p><a class=\"existing_page_link\" href=\"/\">HomePage</a></p>")
  end
  
  #---------------------
  private
  
  def render_both(revision, good_html, options = {})
    html = page_render(revision, options)
    assert_equal(good_html, html, 'PageRenderer error')
    
    html = revision_render(revision, options)
    assert_equal(good_html, html, 'Revision render error')
  end
  
  def revision_render(revision, options)
    html = revision.display_content(options)
  end
  
  def page_render(revision, options = {})
    renderer = PageRenderer.new(revision, options[:render_for_edit] )
    renderer.display_content(options[:update_references])
  end
  
end
