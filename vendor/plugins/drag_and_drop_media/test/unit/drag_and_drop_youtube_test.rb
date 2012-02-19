require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../../config/environment.rb'))


class DragAndDropYoutubeTest < Test::Unit::TestCase

  def test_truth
    assert true
  end

  def test_search

    myyoutube = DragAndDropYoutube.new(:Youtube, "u8VJg3uvnM4",5)
    assert_not_nil myyoutube

    videos = myyoutube.search( 'sequoia', '', 1)
    assert_equal videos.size, 5
    #videos.each {|ps|   puts "Video Title: '#{ps[:title]}' User: '#{ps[:creator]}'" }
    # assert_equal videos[3][:title], "Classic Sequoia"
    
    videos = myyoutube.search( '', 'loveokapi', 1)
    assert_equal videos.size, 5
    #videos.each {|ps|   puts "Video Title: '#{ps[:title]}' User: '#{ps[:creator]}'" }
    # assert_equal videos[0][:title], "Little Green Frog and Big Red Bus"
    
    videos = myyoutube.search( 'sequoia', 'loveokapi', 1)
    assert_equal videos.size, 5
    #videos.each {|ps|   puts "Video Title: '#{ps[:title]}' User: '#{ps[:creator]}'" }
    assert_equal videos[0][:title], "Generalissimo Grant"
        
  end

end

