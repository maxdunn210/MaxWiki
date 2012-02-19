require File.dirname(__FILE__) + '/../test_helper'

class PageSetTest < Test::Unit::TestCase
  fixtures :wikis, :pages, :wiki_references
  
  def test_all
    Role.current = ROLE_PUBLIC
    build_wiki
    
    all = @wiki.select_all(:all_pages).by_name
    assert_equal(["About Us", "About Us_left", "About Us_menu", "Contact", "Orphan", "menu"], all.map {|p| p.name})
    
    all = @wiki.select_all(:main_pages).by_name
    assert_equal(["About Us", "Contact", "Orphan"], all.map {|p| p.name})
    
    all = @wiki.select_all(:main_and_layout_pages).by_name
    assert_equal(["About Us", "Contact", "Orphan", "menu"], all.map {|p| p.name})
  end
  
  def test_all_role_admin
    Role.current = ROLE_ADMIN
    build_wiki
    all = @wiki.select_all(:all_pages).by_name
    assert_equal(["About Us", "About Us_left", "About Us_menu", "Admin Info", "Contact", "Orphan", "menu"], all.map {|p| p.name})
  end
    
  def test_orphan
    Role.current = ROLE_PUBLIC
    build_wiki
    orphans = @wiki.select_all(:all_pages).by_name.orphaned_pages
    assert_equal(['Orphan'], orphans.map {|p| p.name})
  end
  
  def test_wanted
    # If ROLE_PUBLIC, then "Admin Info" page will appear as a wanted page. So do this check
    # with ROLE_ADMIN
    Role.current = ROLE_ADMIN
    build_wiki
    wanted = @wiki.select_all(:all_pages).by_name.wanted_pages
    assert_equal(["Wanted Page"], wanted)
  end
  
  def test_wanted_by
    Role.current = ROLE_PUBLIC
    build_wiki
    assert_equal(['menu'], @wiki.select(:all_pages).pages_that_reference('Wanted Page').map {|p| p.name})
  end  
  
end
