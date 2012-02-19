require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../../config/environment.rb'))

class DragAndDropAmazonTest < Test::Unit::TestCase

  def test_truth
    assert true
  end
  
  def test_search_music
    d = DragAndDropAmazon.new( :Amazon, "0XPTBGCTMB4S1B18QC82", 'rolling stones', 'Music' )
    assert_not_nil d
    
    
    results = d.search
    assert_equal results.size, 10
    # results.each { |r| puts r[:title] }
    # of course these results can change easily.... 
    assert_equal results[0][:title], "Exile on Main St."
    results = d.search( 'pink floyd', nil, 3)
    assert_equal results.size, 10
    # results.each { |r| puts r[:title] }
    # of course these results can change easily.... 
    assert_equal results[2][:title], "Echoes: The Best of Pink Floyd"
    
  end
  def test_search_books
    d = DragAndDropAmazon.new( :Amazon, "0XPTBGCTMB4S1B18QC82", 'Goethe', 'Books' )
    assert_not_nil d
    results = d.search( 'okapi', nil, 1)
    assert_equal results.size, 10
    # results.each { |r| puts r[:title] }
    # of course these results can change easily.... 
    assert_equal results[8][:title], "L'okapi: Roman (D'aujourd'hui)"
    
  end

end

