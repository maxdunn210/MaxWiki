require File.dirname(__FILE__) + '/../test_helper'

class RailsPatchesTest < Test::Unit::TestCase

  def test_blank
    assert(nil.blank?, "nil.blank?")
    assert(''.blank?, "''.blank?")
    assert([].blank?, "[].blank?")
    assert({}.blank?, "{}.blank?")
  end

  def test_entries
    list = Dir.entries('test')
    list.delete_if {|i| i.starts_with?('.') && i.size > 2}  # Get rid of variable directories like .svn and .DS_Store
    assert_equal([".", "..", "fixtures", "functional", "integration", "mocks", "test_helper.rb", "unit"].sort, list.sort)
    
    list = Dir.entries('test', :nodots)
    assert_equal(["fixtures", "functional", "integration", "mocks", "test_helper.rb", "unit"].sort, list.sort)

    list = Dir.entries('test', :directories, :nodots)
    assert_equal(["fixtures", "functional", "integration", "mocks", "unit"].sort, list.sort)

    list = Dir.entries('test', :files, :nodots)
    assert_equal(["test_helper.rb"], list)
  end
  
  include ActionView::Helpers::DateHelper
  
  def test_hour_select
    expected = %(<select id="date_hour" name="date[hour]">\n)
    expected << %(<option value=\"0\">12am</option>\n<option value=\"1\">1am</option>\n<option value=\"2\">2am</option>\n<option value=\"3\">3am</option>\n<option value=\"4\">4am</option>\n<option value=\"5\">5am</option>\n<option value=\"6\">6am</option>\n<option value=\"7\">7am</option>\n<option selected=\"selected\" value=\"8\">8am</option>\n<option value=\"9\">9am</option>\n<option value=\"10\">10am</option>\n<option value=\"11\">11am</option>\n<option value=\"12\">12pm</option>\n<option value=\"13\">1pm</option>\n<option value=\"14\">2pm</option>\n<option value=\"15\">3pm</option>\n<option value=\"16\">4pm</option>\n<option value=\"17\">5pm</option>\n<option value=\"18\">6pm</option>\n<option value=\"19\">7pm</option>\n<option value=\"20\">8pm</option>\n<option value=\"21\">9pm</option>\n<option value=\"22\">10pm</option>\n<option value=\"23\">11pm</option>\n)
    expected << "</select>\n"

    assert_dom_equal expected, select_hour(Time.mktime(2003, 8, 16, 8, 4, 18))
  end
  
end