require File.dirname(__FILE__) + '/../test_helper'

class RoleTest < Test::Unit::TestCase
  fixtures :system, :wikis, :pages, :revisions

  def test_config
    assert_equal({"Public"=>[], "User"=>["Public"], "Editor"=>["User"], "Admin"=>["Editor"]}, MY_CONFIG[:roles])
  end
  
  def test_roles
    assert_equal({"Public"=>[], "User"=>["Public"], "Editor"=>["User"], "Admin"=>["Editor"]}, Role.role_table)
  end  

  def test_check_roles
    assert(Role.check_roles('Editor', 'Public'))
  end
  
private
end

