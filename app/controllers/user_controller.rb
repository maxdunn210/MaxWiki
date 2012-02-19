class SignupException < RuntimeError
end

class UserController < ApplicationController
  
  layout  'main'
  
  # change_password has it's own security
  before_filter :authorize_user, :except => [:index, :my_account, 
  :login, :logout, :signup, :verify_signup, :complete_signup, 
  :change_password, :reset_password, :restore_deleted]
  before_filter :authorize_admin, :only => :import
  
  def index
    redirect_to :action => 'my_account'
  end
  
  def login
    return if generate_blank
    @user = User.new(params[:user]) #save form data in case of error
    login = params[:user][:login]
    password = params[:user][:password]
    
    auth = User.authenticate_all(login, password)
    unless auth.error? || (auth.user && auth.user.errors.any?)
      set_user(auth.user)
      flash[:notice] = 'Login successful'
      redirect_to_welcome
    else
      clear_user
      @login = params[:user][:login]
      flash.now[:notice] = 'Login unsuccessful'
      flash.now[:error] = ''
      flash.now[:error] << auth.error_msg if auth.error?
      flash.now[:error] << auth.user.errors.full_messages.to_sentence if auth.user && auth.user.errors.any?
    end
  end
  
  # Signup
  # 
  # If GET, then we need to generate the form
  #   - Save the calling URL because this can be called directly from this controller, and also as a component
  #   of a wiki page
  #   - Also get the @user object because if there was an error previously posting the form, we want to retain
  #   the data and show the error
  #   - Also check to see if we want to suppress the layout (when calling as a component)
  # If PUT then we are saving the data
  #   - If any error, then go back to the previous page (which could be this controller or a wiki page)
  def signup
    if request.method == :get
      save_url(:last_signup_url)
      
      @user = flash[:signup_user]
      render :layout => !params[:no_layout] 
      return
    end
    
    begin
      @user = User.new(params[:user])      
      @user.login = @user.email
      
      if User.signup_closed?
        @user.wait_list_pos = User.next_wait_list_pos
      end
      
      unless save_and_send_signup_email(true, @wiki.config[:signup_cc_to])
        raise SignupException
      end
      
      unless @wiki.config[:signup_survey].blank?
        survey = Survey.find(params[:survey_id])
        survey.add_or_update_response(params[:answers], @user, session)      
      end
      
      render :action => 'wait_for_email'
      
    rescue SignupException
      flash[:signup_user] = @user
      redirect_to_last_url(:last_signup_url, {:controller => 'user', :action => 'signup'})
    end
  end
  
  def complete_signup
    user = user_authenticate_by_token
    if user
      if user.wait_list?
        msg = "Your account is now activated and you have been placed on the waiting list. " +
          "You may login to gain some additional access to this site."
      else
        msg = "Your account is now activated. Please login."
      end
      
      flash[:notice] = msg
      
      # They are signed in here. Log them out so they have to login manually.
      clear_user
      redirect_to :action => 'login'
    else
      redirect_to :action => 'verify_signup'
    end
  end
  
  def logout
    clear_user
  end
  
  def change_password
    unless logged_in?
      @user = user_authenticate_by_token
      if @user.nil?
        redirect_to :action => 'reset_password'
        return
      end
    end
    
    return if generate_filled_in
    
    begin
      @user.change_password(params[:user][:password], params[:user][:password_confirmation])
      @user.save!
      
      url = url_for(:controller => 'wiki', :action => 'show')
      deliver_now { UserNotify.deliver_change_password(@user, url, @wiki.config) }
      flash[:notice] = "Your password has been updated, and a reminder emailed to #{@user.email}."
      redirect_to_welcome
    rescue StandardError => e
      # Don't catch RecordInvalid errors because these will be show separately through "error_messages_for('user')"
      unless e.is_a?(ActiveRecord::RecordInvalid)
        flash.now[:error] = e.to_s
      end
    end
  end
  
  def reset_password
    # Always redirect if logged in
    if logged_in?
      flash[:notice] = 'You are currently logged in. You may change your password now.'
      redirect_to :action => 'change_password'
      return
    end
    
    # Render on :get and render
    return if generate_blank
    
    # Handle the :post
    if check_email(params[:user][:email])
      fix_login(@user)
      begin
        key = @user.generate_security_token
        url = url_for(:action => 'change_password')
        url += authentication_key(key)
        deliver_now { UserNotify.deliver_reset_password(@user, url, @wiki.config) }
        flash.now[:notice] = "Instructions on resetting your password have been emailed to #{params[:user][:email]}"
        
        #clear out user email to provide feedback that it was processed
        @user = nil
      rescue StandardError => e
        unless e.is_a?(ActiveRecord::RecordInvalid)
          flash.now[:error] = e.to_s
        end
      end
    end
  end
  
  def edit
    return if generate_filled_in
    
    changeable_fields = ['firstname', 'lastname', 'email']
    user_params = params[:user].delete_if { |k,v| not changeable_fields.include?(k) }
    @user.attributes = user_params
    if @user.save
      set_user(@user)
      flash[:notice] = "Changes saved"
      redirect_to :action => 'my_account'
    end  
  end
  
  def delete
    return if request.method == :get || params[:confirm].blank?
    
    @user = find_user_from_session_id
    begin
      if UserSystem::CONFIG[:delayed_delete]
        key = @user.set_delete_after
        url = url_for(:action => 'restore_deleted')
        url += authentication_key(key)
        deliver_now {UserNotify.deliver_pending_delete(@user, url, @wiki.config)}
      else
        destroy(@user)
      end
      logout
    rescue StandardError => e
      unless e.is_a?(ActiveRecord::RecordInvalid)
        flash[:error] = e.to_s
      end
    end
    redirect_to :action => 'my_account'
  end
  
  def restore_deleted
    user = user_authenticate_by_token
    if user.nil?
      flash.now[:error] = 'The account for Unknown was not restored. Please try the link again.'
      redirect_to :action => 'login'
    else
      user.deleted = 0
      if not user.save
        flash.now[:error] = "The account for #{user[:login]} was not restored. Please try the link again."
        redirect_to :action => 'login'
      else
        redirect_to_welcome
      end
    end
  end
  
  def my_account
  end
  
  def verify_signup
    # Render on :get and render
    return if generate_blank  
    
    if check_email(params[:user][:email])
      if @user.verified?
        flash.now[:notice] = 'User has already been verified.'
      else
        fix_login(@user)
        if save_and_send_signup_email(false)
          render :action => 'wait_for_email'
        end
      end
    end
  end
  
  def import
    return if request.method == :get
    
    @good_emails = []
    @bad_emails = []
    url = url_for(:action => 'login')    
    emails = params[:emails].scan(/\b#{EMAIL_VALID_RE_STR}\b/mi)
    
    emails.each do |email|
      if User.find_by_email(email)
        @bad_emails << email + ' - Duplicate'
        next
      end
      
      email =~ /^(.*)@/
      email_base = $1
      
      begin
        User.transaction do
          user = User.new
          user.login = email
          user.email = email
          user.firstname = email_base
          password = random_password
          user.change_password(password)
          fix_login(user)
          mark_user_verified(user)
          user.save!
          
          deliver_now { UserNotify.deliver_imported(user, url, password, @wiki.config) }
          @good_emails << email
        end
      rescue StandardError => e
        @bad_emails << "#{email} - #{e}" 
      end
    end
    
    render :action => 'import_done'
  end
  
  #---------------------------
  private
  
  def random_password(len = 8)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    chars.reject! {|c| '0oO1l'.include?(c)} #Take out chars that are easy to confuse
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end
  
  def destroy(user)
    deliver_now {UserNotify.deliver_delete(user, nil, @wiki.config)}
    flash[:notice] = "The account for #{user[:login]} was successfully deleted."
    user.destroy()
  end
  
  # Generate a template user for certain actions on get
  def generate_blank
    case request.method
    when :get
      @user = User.new
      render :layout => !params[:no_layout]
      return true
    end
    return false
  end
  
  # Generate a template user for certain actions on get
  def generate_filled_in
    @user = find_user_from_session_id
    case request.method
    when :get
      render :layout => !params[:no_layout]
      return true
    end
    return false
  end
  
  def find_user_from_session_id
    session_user = session[:user]
    return nil if session_user.nil?
    User.find(session[:user][:id])
  end
  
  def redirect_to_welcome
    if MY_CONFIG[:welcome_page].nil? || MY_CONFIG[:welcome_page].empty?
      redirect_to :action => 'my_account'
    else
      redirect_to :controller => 'wiki', :action => 'show', :link => MY_CONFIG[:welcome_page].downcase
    end  
  end   
  
  def save_and_send_signup_email(new_password, cc = nil)  
    send_ok = false
    begin
      User.transaction do
        
        if new_password 
          @user.new_password = true
          unless @user.save
            return false
          end
        end
        
        key = @user.generate_security_token
        url = url_for(:controller => 'user', :action => 'complete_signup')
        url += authentication_key(key)
        
        deliver_now { UserNotify.deliver_signup(@user, url, @wiki.config) }
        deliver_now { UserNotify.deliver_signup(@user, url, @wiki.config, cc) } unless cc.blank? 
        
        flash[:notice] = 'Verification email sent'
        send_ok = true
      end
    rescue StandardError => e
      flash.now[:error] = "Error creating account: #{e}" 
    end
    
    return send_ok
  end  
  
  def check_email(email)
    email_ok = false
    @user = nil
    if email.nil? or email.empty?
      flash.now[:error] = 'Please enter a valid email address.'
    else 
      @user = User.find_by_email(email)
      if @user.nil?
        flash.now[:error] = "We could not find a user with the email address #{email}."
      else
        email_ok = true
      end
    end
    
    return email_ok
  end  
  
  def fix_login(user)
    user.login = user.email if user.login.blank?
    user.save!
  end
  
  def mark_user_verified(user)
    user.verified = true
    user.role = @wiki.config[:default_role] if user.role.blank?
    user.save!
  end      
  
  def user_authenticate_by_token
    user = nil
    error = nil
    user_id = params['id']
    key = params['key']
    user, error = User.authenticate_token(user_id, key)
    
    if user
      fix_login(user)
      mark_user_verified(user)
      set_user(user)
    else
      case error
      when :token_not_found
        flash[:error] = 'The authentication key is incorrect and is likely too old. Please try again and click on the authentication link in the new email.'
      when :expired 
        flash[:error] = 'This authentication key has expired. Please try again and click on the authentication link in the new email.'
      when :token_too_short
        flash[:error] = 'This authentication key is too short. Please try copying-and-pasting the entire authenticaion link into the browser address bar.'
      when :damaged
        flash[:error] = 'This authentication link format is not correct. Please try copying-and-pasting the entire authentication link into the browser address bar.'
      else  
        flash[:error] = 'There was an unknown problem with this authentication link. Please try again and click on the authentication link in the new email.'
      end   
    end
    return user
  end
  
  def authentication_key(key)
    "?id=#{@user.id}&key=#{key}"
  end  
  
end
