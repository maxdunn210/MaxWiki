require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../../config/environment.rb'))

class DragAndDropDavetvTest < Test::Unit::TestCase

  def test_truth
    assert true
  end

  def test_search_video
    d = DragAndDropDavetv.new( :DaveTV, 5 )
    assert_not_nil d
    
    results = d.search( 'cool', '4498')
    # these results are dynamic, may change over time
    assert_equal results.size, 1
    #results.each_with_index { |r,i| puts "#{i}: #{r[:title]}" }
    assert_equal results[0][:title], "The new DAVE.TV embeddable player."
     
  end



# smoketest
=begin
d = WDavetv.new( :DaveTV, 5 )
results = d.search( 'cool')
results.each do |r|
  puts r[:title]
end
puts "5 titles ?"
results = d.search( 'cool', '4405')
results.each do |r|
  puts r[:title]
end
puts "5 titles ?"

=end
end

