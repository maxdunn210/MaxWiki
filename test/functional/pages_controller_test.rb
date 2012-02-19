require File.dirname(__FILE__) + '/../test_helper'
require 'pages_controller'

# Re-raise errors caught by the controller.
class PagesController; def rescue_action(e) raise e end; end

class PagesControllerTest < Test::Unit::TestCase
  fixtures :pages, :revisions, :wikis
  
  def setup
    @controller = PagesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end
  
  def test_need_login    
    get :edit, :id => 1
    assert_redirected_to :action => 'login'
    
    post :update, :id => 1
    assert_redirected_to :action => 'login'
  end
  
  def test_edit
    login_admin
    get :edit, :id => 48
    
    assert_no_errors
    select = assert_select 'div#middle_column>form>table>tr>td'
    assert_equal('Textile Sample', select[2].children[0].attributes['value'])    
    assert_equal('textile_sample', select[5].children[0].attributes['value'])    
    assert_equal('2006-03-07 09:20:21', select[8].children[0].attributes['value'])    
    assert_equal('Max Dunn', select[15].children[0].attributes['value'])    
  end
  
  def test_update
    new_created_at = '2007-01-01 10:20:00'
    new_author = 'Joe Blight'
    
    login_admin
    post :update, :id => 48, :page => {:created_at => new_created_at}, :first => {:author => new_author}
    assert_response :redirect
    assert_redirected_to :action => 'list'
    assert_no_errors
    
    page = Page.find(48)
    assert_equal('Mon, 01 Jan 2007 10:20:00 -0800', page.created_at.rfc822)
    assert_equal(new_author, page.author)
  end
  
end
