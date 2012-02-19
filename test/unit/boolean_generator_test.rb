require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../lib/boolean_generator'

class SQLGeneratorTest < Test::Unit::TestCase
  
  def test_simple1
      bool = BooleanGenerator.new
      bool.add('c1', 'and')
      bool.add('c2')
      assert_equal "c1 and c2", bool.to_s
  end

  def test_simple2
      bool = BooleanGenerator.new
      bool.add('c1', 'and')
      bool.paren_open
      bool.add('c2', 'or')
      bool.add('c3')
      bool.paren_close
      assert_equal "c1 and (c2 or c3)", bool.to_s
  end

  def test_simple3
      bool = BooleanGenerator.new
      bool.add('c1', 'and')
      bool.paren_open
      bool.add('c2', 'or')
      bool.add('c3')
      bool.paren_close('and')
      bool.add('c4')
      assert_equal "c1 and (c2 or c3) and c4", bool.to_s
  end

  def test_simple4
      bool = BooleanGenerator.new
      bool.add('c1', 'and')
      bool.paren_open
      bool.add('c2', 'or')
      bool.paren_open
      bool.add('c3', 'and')
      bool.add('c4')
      bool.paren_close('or')
      bool.add('c5')
      bool.paren_close('and')
      bool.add('c6')
      assert_equal "c1 and (c2 or (c3 and c4) or c5) and c6", bool.to_s
  end

  def test_event_test_conditions
    assert_equal "date and kind and (event or (team and level))", 
      event_condition('date', 'kind', 'event', 'team', 'level')

    assert_equal "kind and (event or (team and level))", 
      event_condition('', 'kind', 'event', 'team', 'level')

    assert_equal "date and kind and (event or (team))", 
      event_condition('date', 'kind', 'event', 'team', '')

    assert_equal "date and kind and (event or (level))", 
      event_condition('date', 'kind', 'event', '', 'level')

    assert_equal "date and kind and (event)", 
      event_condition('date', 'kind', 'event', '', '')

    assert_equal "date and kind", 
      event_condition('date', 'kind', '', '', '')

    assert_equal "date", 
      event_condition('date', '', '', '', '')

    assert_equal "kind", 
      event_condition('', 'kind', '', '', '')

    assert_equal "(event or (team and level))", 
      event_condition('', '', 'event', 'team', 'level')

    assert_equal "((team))", 
      event_condition('', '', '', 'team', '')

  end
  
  def test_event_conditions
    date = "TO_DAYS(date_time) >= TO_DAYS(NOW())"
    kind = nil
    event = "events.kind = 'Event'"
    team = "home_team.id = '1' or visitor_team.id = '1'"
    level = nil
    assert_equal "#{date} and (#{event} or (#{team}))", 
      event_condition(date, kind, event, team, level)

  end
  
  private
  
  def event_condition(date, kind, event, team, level)
      bool = BooleanGenerator.new
      bool.add("#{date}", 'and')
      bool.add("#{kind}", 'and')
      bool.paren_open
      bool.add("#{event}", 'or')
      bool.paren_open
      bool.add("#{team}", 'and')
      bool.add("#{level}")
      bool.paren_close
      bool.paren_close
      bool.to_s
  end
  
end
