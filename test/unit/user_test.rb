require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  
  fixtures :adults, :wikis

  def test_new
    user = User.new
    assert_equal 1, user.wiki_id, "Wrong wiki_id"
  end  
      
  def test_auth
    auth = User.authenticate("bob", "atest")
    assert(!auth.error?, auth.error_msg)
    
    
    auth = User.authenticate("nonbob", "atest")
    assert(auth.error?, auth.error_msg)
    assert_equal(Authorization::NOT_FOUND, auth.error_type, auth.error_msg)
  end

  def test_password_change
    # Get the user and change the password
    user = User.find(1052)
    user.change_password("nonbobpasswd")
    user.save
    
    # Make sure the new password works and the old one doesn't
    auth = User.authenticate("longbob", "nonbobpasswd")
    assert(!auth.error?, auth.error_msg)
    assert_equal(user, auth.user, auth.error_msg)
    
    auth = User.authenticate("longbob", "alongtest")
    assert_equal(Authorization::NOT_AUTHORIZED, auth.error_type)
    
    # change the password back
    user.change_password("alongtest")
    user.save
    
    # Now check again
    auth = User.authenticate("longbob", "alongtest")
    assert(!auth.error?, auth.error_msg)
    assert_equal(user, auth.user, auth.error_msg)

    auth = User.authenticate("longbob", "nonbobpasswd")
    assert_equal(Authorization::NOT_AUTHORIZED, auth.error_type)
  end
  
  def test_disallowed_passwords
    u = User.new    
    u.login = "nonbob@test.com"
    u.email = "nonbob@test.com"

    u.change_password("tiny")
    assert !u.save     
    assert u.errors.invalid?('password')

    u.change_password("hugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehuge")
    assert !u.save     
    assert u.errors.invalid?('password')
        
    u.change_password("")
    assert !u.save    
    assert u.errors.invalid?('password')
        
    u.change_password("bobs_secure_password")
    assert u.save     
    assert u.errors.empty?
        
  end
  
  def test_bad_logins
    u = User.new  
    u.change_password("bobs_secure_password")

    u.email = "x"
    assert !u.save     
    assert u.errors.invalid?('email')
    
    u.email = "hugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhug"
    assert !u.save     
    assert u.errors.invalid?('email')

    u.email = ""
    assert !u.save
    assert u.errors.invalid?('email')

    u.email = "okbob@test.com"
    assert u.save  
    assert u.errors.empty?
  end


  def test_collision
    u = User.new
    u.login = "existingbob"
    u.change_password("bobs_secure_password")
    assert !u.save
  end


  def test_create
    u = User.new
    u.login = "nonexistingbob@test.com"
    u.email = "nonexistingbob@test.com"
    u.change_password("bobs_secure_password")
      
    assert u.save  
    
  end
  
end
