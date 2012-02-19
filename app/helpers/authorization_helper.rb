module AuthorizationHelper

  def logged_in?
    session[:user]
  end

  def session_role
    session[:user][:role] rescue ROLE_PUBLIC
  end
  
  def authorized_pages!(pages)
    pages.select {|page| Role.check_role(page.access_read) } unless pages.nil?
  end

end
