require File.dirname(__FILE__) + '/../test_helper'

class PlayerTest < Test::Unit::TestCase
  fixtures :players, :wikis

  def test_new
    player = Player.new
    assert_equal 1, player.wiki_id, "Wrong wiki_id"
  end  

  def test_league_age
    assert_equal 14, players(:Maxie_Dunn).league_age(2010)
    assert_equal 11, players(:Claire_Dunn).league_age(2010)
    assert_equal 13, players(:Birthday_Before).league_age(2010)
    assert_equal 12, players(:Birthday_After).league_age(2010)
  end  
  
  def test_find_player
    user = User.find_by_household_id(1001)
    players = Player.find_all_by_user(user)
    assert_equal(0, players.size)
    
    user = User.find_by_household_id(1006)
    players = Player.find_all_by_user(user)
    assert_equal(3, players.size)
    assert_equal(["Claire", "Jamie", "Maxie"], players.map {|p| p.firstname}.sort)
    
    players = Player.find_all_by_user(user, :fee_paid)
    assert_equal(1, players.size)
    assert_equal("Jamie", players[0].firstname)
    
    players = Player.find_all_by_user(user, :info_checked)
    assert_equal(1, players.size)
    assert_equal("Jamie", players[0].firstname)

    players = Player.find_all_by_user(user, :fee_paid, :info_checked)
    assert_equal(1, players.size)
    assert_equal("Jamie", players[0].firstname)
  end
end
