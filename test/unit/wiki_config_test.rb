require File.dirname(__FILE__) + '/../test_helper'

class WikiConfigTest < Test::Unit::TestCase
  fixtures :system, :wikis
  
  def test_roles
    assert_equal(["User", "Public", "Admin", "Editor"].sort, WikiConfig.roles.sort)
  end
  
  def test_themes
    assert_equal(["abt",
 "baseball",
 "camp",
 "church",
 "clean",
 "maxwiki",
 "okaapi",
 "pawprint",
 "personal1",
 "pta",
 "red",
 "sports1"].sort, WikiConfig.themes.sort)
  end
end
