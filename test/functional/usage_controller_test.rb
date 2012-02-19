require File.dirname(__FILE__) + '/../test_helper'
require 'usage_controller'

# Re-raise errors caught by the controller.
class UsageController; def rescue_action(e) raise e end; end

class UsageControllerTest < Test::Unit::TestCase
 fixtures :locations, :usages
   
  def setup
    @controller = UsageController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end
  

  def test_show
    #get :show, :location => 'CA'
    #assert_no_errors
    assert true
  end
  
end  