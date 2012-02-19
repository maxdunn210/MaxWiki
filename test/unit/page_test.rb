require File.dirname(__FILE__) + '/../test_helper'

class PageTest < Test::Unit::TestCase
  fixtures :wikis, :system, :revisions, :pages
  
  def test_save_illegal
    name = "Jim's & Mary's?"
    link = "jims_marys"
    content = 'Page with illegal characters in the name'
    content_type = 'html'
    parent = nil
    access = {}
    time = Time.now
    author = 'Test Author'
  
    page = Page.new(:name => name, :wiki_id => @wiki.id)
    page.revise(content, content_type, parent, access, time, author)    
    assert_equal(link, page.link)
  end
  
end
