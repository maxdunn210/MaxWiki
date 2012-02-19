class AuthorizationController < ActionController::Base

  include AuthorizationHelper

  def set_user(user)
    session[:user] = {}
    session[:user][:id] = user.id
    session[:user][:role] = user.role
    session[:user][:firstname] = user.firstname
    session[:user][:lastname] = user.lastname
    set_authorization_role
  end
  
  def clear_user
    session[:user] = nil
    set_authorization_role
  end
  
  # Set a cookie with the role so the cached pages can show the correct content
  # for that role
  # Also set the Role.current so models can have access to the role
  def set_authorization_role
    cookies['role'] = { :value => session_role, :expires => Time.utc(2030) }
    Role.current = session_role
  end
  
protected

  def authorize(role, msg)
    unless Role.check_role(role)
      flash[:notice] = msg
      access_denied
    end
  end
    
  def authorize_admin     
    authorize(ROLE_ADMIN, "Please log in as an admin user")
  end
  
  def authorize_editor               
    authorize(ROLE_EDITOR, "Please log in as a user with an editor or admin role")
  end
  
  def authorize_user
    authorize(ROLE_USER, "Please log in")
  end
  
  def access_denied
    store_location
    redirect_to :controller => "user", :action => "login"
    return false
  end  
  
  #MD Need to take this out, user our normal authentication for system maintenance
  def password_error(password)
    if password.nil? or password.empty?
      'Please enter the password.'
    else 
      'You entered a wrong password. Please enter the right one.'
    end
  end

private

end
