require File.dirname(__FILE__) + '/../test_helper'

class EmailTest < Test::Unit::TestCase
  fixtures :emails, :wikis

  def test_new
    email = Email.new
    assert_equal 1, email.wiki_id, "Wrong wiki_id"
  end
end
