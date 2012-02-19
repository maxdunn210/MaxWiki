require File.dirname(__FILE__) + '/../test_helper'

class HouseholdTest < Test::Unit::TestCase
  fixtures :households, :wikis

  def test_new
    household = Household.new
    assert_equal 1, household.wiki_id, "Wrong wiki_id"
  end
end
