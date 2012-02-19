require File.dirname(__FILE__) + '/../test_helper'

class MailerTest < Test::Unit::TestCase
  fixtures :mailers, :wikis

  def setup
    setup_wiki
  end
  
  def test_new
    mailer = Mailer.new
    assert_equal 1, mailer.wiki_id, "Wrong wiki_id"
  end  

end
