require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../../config/environment.rb'))

class DragAndDropItunesTest < Test::Unit::TestCase

  def test_truth
    assert true
  end
=begin
  Itunes doesn't work...
  def test_search_music
    d = DragAndDropItunes.new( :Itunes, 8, 'pink floyd', 'song' )
    assert_not_nil d

    results = d.search
    assert_equal results.size, 8
    # results.each_with_index { |r,i| puts i; puts r[:title]; puts r[:thumb] }
    # it's pure luck if this passes.... 
    assert_equal results[0][:title], "Another Brick in the Wall"
    assert_equal results[0][:thumb], 
        "http://a1.phobos.apple.com/r10/Music/y2003/m04/d16/h21/s03.eajtonaw.60x60-50.jpg"
  end
=end
end

