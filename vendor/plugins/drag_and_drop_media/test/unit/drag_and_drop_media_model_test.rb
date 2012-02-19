require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../../config/environment.rb'))

class DragAndDropMediaModelTest < Test::Unit::TestCase

  def test_truth
    assert true
  end

  def test_search_tag
    
    m = DragAndDropMediaModel.new( 4 )
    assert_not_nil m
    
    result = m.search('testtag')
    result.each_with_index { |r,i| assert_equal r, 'tag_' + (i+1).to_s }
   
    m.forward
    result = m.search('testtag')
    result.each_with_index { |r,i| assert_equal r, 'tag_' + (i+9).to_s } 
    result = m.search('testtag')
    result.each_with_index { |r,i| assert_equal r, 'tag_' + (i+9).to_s } 
    result = m.search()
    result.each_with_index { |r,i| assert_equal r, 'tag_' + (i+9).to_s } 
             
  end
  
  def test_search_user
    
    m = DragAndDropMediaModel.new( 4 )
    assert_not_nil m
    
    result = m.search(nil,'testuser')
    result.each_with_index { |r,i| assert_equal r, 'user_' + (i+1).to_s }
   
    m.forward
    result = m.search
    result.each_with_index { |r,i| assert_equal r, 'user_' + (i+9).to_s }
             
  end  
  
  def test_search_tag_and_user
  
    m = DragAndDropMediaModel.new( 4 )
    assert_not_nil m
    
    result = m.search(nil,'testuser')
    result.each_with_index { |r,i| assert_equal r, 'user_' + (i+1).to_s }
    result = m.search('testtag')
    result.each_with_index { |r,i| assert_equal r, 'tag_' + (i+1).to_s } 
    
  end
  
  def test_search_no_result  
    m = DragAndDropMediaModel.new( 4 )
    assert_not_nil m
    
    result = m.search('test')      
    assert result.size, 0
  end
  
end
