require File.dirname(__FILE__) + '/../test_helper'

class EventTest < Test::Unit::TestCase
  fixtures :events, :lookups, :wikis
  
  def setup
    super
    @event = Event.find(1)
  end

  def test_new
    event = Event.new
    assert_equal 1, event.wiki_id, "Wrong wiki_id"
  end

  def test_create
    assert_kind_of Event, @event
    assert_equal events(:giants_game).id, @event.id
    assert_equal events(:giants_game).kind, @event.kind
    assert_equal events(:giants_game).name, @event.name
    assert_equal events(:giants_game).date_time, @event.date_time
    assert_equal events(:giants_game).length, @event.length
    assert_equal events(:giants_game).home_team_id, @event.home_team_id
    assert_equal events(:giants_game).location_id, @event.location_id
    assert_equal events(:giants_game).visitor_team_id, @event.visitor_team_id
    assert_equal events(:giants_game).note, @event.note
    assert_equal 1, @event.wiki_id, "Wrong wiki_id"
  end
  
  def test_schedule_conflicts
    conflicts = events(:giants_game).check_schedule_conflicts
    assert_equal events(:conflict_game), conflicts[0]
    assert_equal events(:conflict_long_practice), conflicts[1]
    assert_equal events(:conflict_short_practice), conflicts[2]
    assert_equal events(:conflict_overlap_practice), conflicts[3]
    assert_equal 4, conflicts.length
  end
  

end
