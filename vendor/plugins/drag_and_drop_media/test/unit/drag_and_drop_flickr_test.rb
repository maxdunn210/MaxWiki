require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../../config/environment.rb'))

class DragAndDropFlickrTest < Test::Unit::TestCase

  def test_truth
    assert true
  end

  def test_search

    wf = DragAndDropFlickr.new(:Flickr, 'd27c153d7883e4730498ceee63c1bacc', 5 )
    assert_not_nil wf

    photos = wf.search( 'leavitt', nil, 1)
    assert_equal photos.size, 5
    #photos.each { |ps| puts "Photo Title: '#{ps[:title]}' User: '#{ps[:creator]}'" }
    assert_equal photos[3][:title], "Leavitt"
    
    photos = wf.search( nil, 'loveokapi', 1)
    assert_equal photos.size, 5
    #photos.each { |ps| puts "Photo Title: '#{ps[:title]}' User: '#{ps[:creator]}'" }
    assert_equal photos[0][:title], "Mexico0506 168"
    
    photos = wf.search( 'loveokapi', nil, 1)
    assert_equal photos.size, 0
    
    photos = wf.search( nil, nil, 1)
    assert_nil photos
        
  end

end

