require File.dirname(__FILE__) + '/../test_helper'

class TeamTest < Test::Unit::TestCase
  fixtures :teams, :lookups, :wikis
  
  def test_new
    team = Team.new
    assert_equal 1, team.wiki_id, "Wrong wiki_id"
  end  
  
  def test_picklist
    picklist = Team.picklist
    assert_equal([["TC Unassigned", 4],
    ["Farm TC Unassigned", 5],
    ["Minors TC As", 3],
    ["Minors TC Blue Jays", 7],
    ["Majors TC Giants", 1],
    ["Majors TC Marlins", 2],
    ["Majors CA As", 6]], picklist)
    
    picklist = Team.picklist(:level_id => 4)
    assert_equal([["TC As", 3], ["TC Blue Jays", 7]], picklist)
    
    picklist = Team.picklist(:home_league_only => true)
    assert_equal([["Unassigned", 4],
    ["Farm Unassigned", 5],
    ["Minors As", 3],
    ["Minors Blue Jays", 7],
    ["Majors Giants", 1],
    ["Majors Marlins", 2]], picklist)
  end
  
  def test_find_team
    team = Team.find_team(:team => 'Giants')
    assert_equal(1, team.id)
    
    team = Team.find_team(:team => 'As')
    assert_equal(3, team.id)
    
    team = Team.find_team(:team => 'As', :level => 'Majors')
    assert_equal(6, team.id)
  end
  
  def test_full_name
    team = Team.find_team(:team => 'Giants')
    assert_equal("Majors TC Giants", team.full_name)
    
    team = Team.find_team(:team => 'Giants')
    assert_equal("TC Giants", team.full_name(one_level = true))
  end
  
  def test_league_and_name
    team = Team.find_team(:team => 'Giants')
    assert_equal("TC:Giants", team.league_and_name)
  end
  
end
