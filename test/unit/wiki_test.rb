require File.dirname(__FILE__) + '/../test_helper'

class WikiTest < Test::Unit::TestCase
  fixtures :system, :wikis, :pages, :revisions
  
  def test_authorized_pages
    base_num = 54
    check_pages('Public', base_num)
    check_pages('Editor', base_num + 1)
    check_pages('Admin', base_num + 2)
  end  
  
  def test_authors
    wiki = Wiki.find(:first)
    assert_equal(["Admin",
     "Max",
     "Max Admin",
     "Max Dunn",
     "Max Dunn Editor",
     "Max1",
     "Max2"],wiki.authors)
  end
  
  private
  def check_pages(role, num)
    Role.current = role
    assert((actual_num = @wiki.authorized_pages.size) == num, "#{role} should have #{num} authorized pages but instead had #{actual_num}")  
  end
end
