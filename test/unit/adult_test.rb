require File.dirname(__FILE__) + '/../test_helper'

class AdultTest < Test::Unit::TestCase
  fixtures :adults, :wikis
  
  def test_new
    adult = Adult.new
    assert_equal 1, adult.wiki_id, "Wrong wiki_id"
  end
  
  def test_count
    if ACTIVE_PLUGINS.include?('maxwiki_multihost')
      num = 11
    else
      num = 12
    end
    assert_equal(num, Adult.count)
  end
end
