require File.dirname(__FILE__) + '/../test_helper'

class LookupTest < Test::Unit::TestCase
  fixtures :lookups, :wikis
  
  def test_new
    lookup = Lookup.new
    assert_equal 1, lookup.wiki_id, "Wrong wiki_id"
  end  

end
