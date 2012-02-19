class AdminController < ApplicationController
  
  include CacheHelper
  layout 'main', :except => [:create_system, :create_wiki]
  before_filter :authorize_admin, :except => [:create_system, :create_wiki]
  
  def create_system
    if @system
      flash[:error] = "System has already been created."
      redirect_home
      return
    elsif request.method == :get
      # no form submitted -> go to template
      @system = System.new
      @system.name = System::DEFAULT_NAME
      @system.description = System::DEFAULT_DESCRIPTION
      
      # For now, just create the system automatically using the defaults. Later if we
      # ask relevant questions, like mail server settings, then we can disable this
      @system.save!
      redirect_home      
      return       
    end
    
    @system = System.setup(params[:system])
    if @system
      flash[:notice] = 'System was successfully created.'
      redirect_home
    else
      render :action => 'create_system'
    end
  end
  
  def create_wiki    
  
    @wiki_exists = false
    if @wiki
      @wiki_exists = true
      flash.now[:error] = "Wiki '#{@wiki.name}' has already been created."
      return
    elsif request.method == :get
      # no form submitted -> go to template
      @wiki = Wiki.new
      @wiki.name = @wiki_name
      @theme = 'maxwiki'
      return       
    end
    
    #Save params here in case there is an error so we can reshow the user data
    @theme = params[:theme]
    @password = params[:password]
    @password_confirmation = params[:password_confirmation]
    @email = params[:email]
    # if 'name' is included in params, use it since this means it is a single host. Otherwise use @wiki_name which
    # will be setup by multi_host
    @wiki = Wiki.new({'name' => @wiki_name}.merge(params[:wiki])) 
    @wiki.brackets_only = true
    @wiki.config = {:site_name => @wiki.description, :theme => @theme, 
      :email_from => @email, :signup_cc_to => @email} 
    
    if params[:password].blank?
      flash[:error] = "Password cannot be blank"
      return
    elsif params[:password] != params[:password_confirmation]
      flash[:error] = "Passwords don't match"
      return
    end
    
    unless @wiki.save
      render :action => 'create_wiki'
      return
    end
    
    user = User.new(:login => 'admin', :email => @email, :lastname => 'Admin', :verified => 1, 
    :role => ROLE_ADMIN)
    user.change_password(@password)  
    user.wiki_id = @wiki.id # Set this manually since the multi_host isn't initialized here
    user.save!
    
    flash[:notice] = "Wiki '#{@wiki.description}' has been created.\n"+
    "Login as 'admin' to edit pages and configure with the Admin menu option." 
    
    redirect_to :controller => 'user', :action => 'login'
  end
  
  def edit_wiki
    system_password = params['system_password']
    if system_password
      # form submitted
      if @system.authenticate(system_password)
        begin
          @wiki.edit_wiki(params['address'], params['name'], 
          params['markup'].intern, 
          params['color'], params['additional_style'], 
          params['safe_mode'] ? true : false, 
          params['password'].empty? ? nil : params['password'],
          params['published'] ? true : false, 
          params['brackets_only'] ? true : false,
          params['count_pages'] ? true : false,
          params['allow_uploads'] ? true : false,
          params['max_upload_size']
          )
          flash[:notice] = "Wiki '#{params['address']}' was successfully updated"
          redirect_home(params['address'])
        rescue Instiki::ValidationError => e
          logger.warn e.message
          flash.now[:error] = e.message
          # and re-render the same template again
        end
      else
        flash.now[:error] = password_error(system_password)
        # and re-render the same template again
      end
    else
      # no form submitted - go to template
    end
  end
  
  def remove_orphaned_pages
    if @system.authenticate(params['system_password_orphaned'])
      @system.remove_orphaned_pages(@wiki_name)
      flash[:notice] = 'Orphaned pages removed'
      redirect_to :controller => 'wiki', :action => 'list'
    else
      flash[:error] = password_error(params['system_password_orphaned'])
      redirect_to :controller => 'admin', :action => 'edit_web'
    end
  end
  
  def params_to_symbols(hash)
    hash[:config].inject({}) {|key, value| params_using_symbols[key.to_sym] = value}
  end
  
  def config
    if request.post? && params[:config]
      params_using_symbols = params[:config].symbolize_keys
      
      @wiki.config = {} if @wiki.config.nil?
      @wiki.config.merge(params_using_symbols)
      if @wiki.save
        flash.now[:notice] = "Configuration saved"
      else
        flash.now[:error] = "Error: #{@wiki.errors.full_messages.to_sentence}"
      end
    end
  end
  
  def expire_cache
    expire_all_pages
  end
  
  def delete_old_sessions
    old_session_query = ['updated_at < ?',Time.now.ago(1.week)]
    
    @old_sessions = Session.delete_all(old_session_query)
    @new_sessions = Session.count
  end
  
  # Not ready yet, code here for template
  # Also need to go through Pages and update the link fields
  def normalize_links  
#    Revision.transaction do
#      pages.each do |page|
#        revision = page.current_revision
#        next if revision.nil? || revision.content.blank?
#        
#        content = revision.content.gsub(/<a(.*?)href=['"]\/([^'"\/]*)['"]/mi) do |match_text|
#          puts "Changing '#{$2}' to '#{Page.create_link($2)}'"
#          "<a#{$1}href=\"/#{create_link($2)}\""
#        end  
#        if content != revision.content
#          revision.content = content
#          revision.save!
#        end
#      end
#    end
  end
  
end
