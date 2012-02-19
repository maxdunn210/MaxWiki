require File.dirname(__FILE__) + '/../test_helper'

class WikiReferenceTest < Test::Unit::TestCase
  fixtures :wikis, :pages, :wiki_references
  
  def test_link_type
    page_type = WikiReference.link_type('Test')
    assert_equal(WikiReference::LINKED_PAGE,page_type)
    
    page_type = WikiReference.link_type('New Page')
    assert_equal(WikiReference::WANTED_PAGE, page_type)
  end
  
  def test_reference
    page_names = WikiReference.pages_that_reference('Teams_Menu');
    assert_equal(["Majors: Mariners_left",
     "Minors: Giants_left",
     "Minors: Padres_left",
     "Minors: Yankees_left",
     "Plus Page",
     "Teams_left",
     "Test Textile"], page_names.sort)
     
    page_names = WikiReference.pages_that_reference("Minors: As_left");
    assert_equal(["Minors: As"], page_names.sort)     

    page_names = WikiReference.pages_that_reference("League Levels");
    assert_equal(["About Us_left",
     "Contact Us_left",
     "League Levels_left",
     "Navigation",
     "Tri-Cities Board_left"], page_names.sort)     
  end
  
  def test_link_to
    page_names = WikiReference.pages_that_link_to("Teams_Menu");
    assert_equal([], page_names.sort)     

    page_names = WikiReference.pages_that_link_to("League Levels");
    assert_equal(["About Us_left",
     "Contact Us_left",
     "League Levels_left",
     "Navigation",
     "Tri-Cities Board_left"], page_names.sort)     
  end
  
  def test_include
    page_names = WikiReference.pages_that_reference('Teams_Menu');
    assert_equal(["Majors: Mariners_left",
     "Minors: Giants_left",
     "Minors: Padres_left",
     "Minors: Yankees_left",
     "Plus Page",
     "Teams_left",
     "Test Textile"], page_names.sort)
  end
  
end
