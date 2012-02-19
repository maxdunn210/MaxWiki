# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.

require 'erbl'

# "require 'user'" is needed to prevent a weird error with edge Rails 5005 on Mongrel
# "A copy of ApplicationController has been removed from the module tree but is still active!"
# 
# 20-Sep-2007 Took this out because it was causing User to have the wrong current_wiki
# when a new wiki was added which would result in not being able to login as the new
# admin until mongrel was restarted
#require 'user'

require 'authorization_controller'

class ApplicationController < AuthorizationController
  
  include ApplicationHelper
  include MaxWiki::ApplicationControllerInclude if defined? MaxWiki::ApplicationControllerInclude
  
  before_filter :connect_to_model, :set_content_type_header, :set_robots_metatag
  after_filter :remember_location, :flash_to_cookie
  filter_parameter_logging :password
  helper_method :session_get
  attr_accessor :wiki
  
  session :off, :if => proc { |request| self.robot?(request.user_agent) }

  def self.robot?(user_agent)
    robot = user_agent.nil? || user_agent =~ /(^-$|Google|Slurp|Baidu|bot|check_http|searchme)/i
    logger.debug "User Agent#{robot ? " Robot" : ""}: #{user_agent}"
    RAILS_ENV == 'test' ? false : robot
  end
   
  def session_get(name)
    name = fix_name(name)
    value = session[name] || DEFAULTS[name]
    fix_value(name, value)
  end
  
  def session_put(name, value)
    name = fix_name(name)
    value = fix_value(name, value)
    session[name] = value
  end
  
  def update_list_filters
    params[:register].each do |name, value|
      session_put(name, value)
    end  
    redirect_to(session[:return_to])
  end
  
  def rescue_action_locally(exception)
    unless system_maintenance(exception)
      super
    end
  end
  
  def rescue_action_in_public(exception)
    unless system_maintenance(exception)
      super
    end
  end
  
  def system_maintenance(exception)
    if exception.class == ActiveRecord::ReadOnlyRecord && MaxWikiActiveRecord.system_read_only_mode
      flash_cookie(MaxWikiActiveRecord.system_read_only_msg)
      redirect_to request.cgi.referer
      true
    else
      false
    end  
  end
  
  #--------------------
  protected
  
  def connect_to_model
    
    # UrlWriter is used for using url_for in wiki pages. However, it needs to know the host
    ActionController::UrlWriter.default_url_options[:host] = (request.port == 80 ? request.host : request.host_with_port)
    
    @system = System.find(:first)
    return if @system.nil?
    MaxWikiActiveRecord.system_read_only_mode = @system.read_only_mode?
    MaxWikiActiveRecord.system_read_only_msg = @system.read_only_msg
    
    # If using Multihost, @wiki_name and @wiki will be setup already or, @wiki_name will be set but @wiki will
    # be nil if the wiki needs to be setup
    # If not using Multihost, then both will be nil so get the first wiki and set the page_cache to "cache"
    # 
    # If not using Multihost, change .htaccess like this to find cached pages in the /public/cache:
    # 
    #  RewriteRule ^$ cache/index.html [QSA]
    #  RewriteRule ^([^.]+)$ cache/$1.html [QSA]
    #  RewriteCond %{REQUEST_FILENAME} !-f
    #  RewriteRule ^(.*)$ dispatch.cgi [QSA,L]
    #  
    #  If instead you put these changes in httpd.conf use a slightly different format:
    #  
    #  RewriteRule ^/?$ /cache/index.html [QSA]
    #  RewriteRule ^/?([^.]+)$ /cache/$1.html [QSA]
    #  RewriteCond %{DOCUMENT_ROOT}%{REQUEST_FILENAME} !-f
    #  RewriteRule ^(.*)$ dispatch.cgi [QSA,L]
    #  
    #  
    #  If using just Mongrel, then to for page caching to work (until Mongrel can look in a 
    #  different directory for the the cached pages) change this to just "#{RAILS_ROOT}/public" 
    #  CAUTION: This will delete all *.html files in the public directory and all directories
    #  below that when doing an "Expire Cache"
    #  
    if @wiki.nil?
      return unless @wiki_name.blank? # Found the wiki_name, but need to setup this wiki
      
      @wiki = Wiki.find(:first)
      return if @wiki.nil? # if no wikis found, need to setup the system
      
      MaxWikiActiveRecord.current_wiki = @wiki
      
      @wiki_name = @wiki.name
      ApplicationController::page_cache_directory = "#{RAILS_ROOT}/public/cache" 
    end  
    
    # Load the theme_default and theme_environment file each time. This file just contains assignments to MY_CONFIG
    # and should be reloaded each time because the user can change the theme, and also in multi-host mode
    # the theme may be different each time this is called.
    # 
    # Require the theme_helper, if it exists. The theme_helper might change if the theme changes, 
    # but we still only want to load it once
    load "#{RAILS_ROOT}/config/theme_defaults.rb"
    unless @wiki.nil? 
      unless @wiki.config[:theme].blank?
        name = "#{RAILS_ROOT}/public/themes/#{@wiki.config[:theme]}/theme_environment.rb"
        load name if File.exist?(name)
        
        name = "#{RAILS_ROOT}/public/themes/#{@wiki.config[:theme]}/theme_helper.rb"
        require name if File.exist?(name)
      end
      unless @wiki.name.blank?
        name = "#{RAILS_ROOT}/public/files/#{@wiki.name}/site_environment.rb"
        load name if File.exist?(name)
        
        name = "#{RAILS_ROOT}/public/files/#{@wiki.name}/site_helper.rb"
        require name if File.exist?(name)
      end
    end
    
    @action_name = params[:action] || 'index'
    
    # Use login name as author when editing pages
    @author = session_user_name
    
    @user = User.find(session[:user][:id]) rescue nil
    if @user.nil?
      @user = User.new
      @user.firstname = 'Not'
      @user.lastname = 'Logged In'
      @user.paid = false
    end
    
    # Set the role cookie and Role.current
    set_authorization_role
    
    # Create default pages if necessary
    @wiki.create_default_pages('admin')
    
    # Make sure that header and footer are available, even for non-wiki pages
    @layout_section_pages = {}
    unless MY_CONFIG[:layout_sections].nil?
      MY_CONFIG[:layout_sections].each do |name|
        @layout_section_pages[name] = @wiki.read_page(name)
      end
    end  
    
    # Set some configuration defaults
    @wiki.config[:default_role] = MY_CONFIG[:default_role] || ROLE_USER if @wiki.config[:default_role].blank?
    
    # Set defaults for Admin or other controllers that aren't wiki pages    
    @left_column_show = TRUE
    @middle_column_size = 'wide'
    
    TRUE #Make sure it returns true to continue the pre_filter chain
  end
  
  FILE_TYPES = {
    '.exe' => 'application/octet-stream',
    '.gif' => 'image/gif',
    '.jpg' => 'image/jpeg',
    '.pdf' => 'application/pdf',
    '.png' => 'image/png',
    '.txt' => 'text/plain',
    '.zip' => 'application/zip'
  } unless defined? FILE_TYPES
  
  def content_type_header(file)
    FILE_TYPES[File.extname(file)] || 'application/octet-stream'
  end
  
  def send_file(file, options = {})
    options[:type] = content_type_header(file)
    options[:stream] = false
    super(file, options)
  end
  
  def redirect_home
    redirect_to_page('HomePage')
  end
  
  def redirect_to_page(page_link)
    redirect_to :controller => 'wiki', :action => 'show', 
    :link => (page_link or 'HomePage')
  end
  
  def redirect_back_or_default(default)
    if session[:return_to].nil?
      redirect_to default
    else
      redirect_to_url session[:return_to]
      session[:return_to] = nil
    end
  end
  
  def remember_location
    if request.method == :get and 
      response.headers['Status'] == '200 OK' and not
        %w(locked save back file pic import login logout).include?(action_name)
      store_location  
    end
  end
  
  def store_location
    session[:return_to] = request.request_uri
    logger.debug "Session ##{session.object_id}: remembered URL '#{session[:return_to]}'"
  end
  
  def rescue_action_in_public(exception)
    render :status => 500, :text => <<-EOL
      <html><body>
        <h2>Internal Error</h2>
        <p>An application error occurred while processing your request.</p>
        <!-- \n#{exception}\n#{exception.backtrace.join("\n")}\n -->
      </body></html>
    EOL
  end
  
  def return_to_last_remembered
    # Forget the redirect location
    redirect_target = session[:return_to] 
    session[:return_to] = nil
    tried_home = session[:tried_home] 
    session[:tried_home] = false
    
    # then try to redirect to it
    if redirect_target.nil?
      if tried_home
        raise 'Application could not render the index page'
      else
        logger.debug("Session ##{session.object_id}: no remembered redirect location, trying home")
        redirect_home
      end
    else
      logger.debug("Session ##{session.object_id}: " +
          "redirect to the last remembered URL #{redirect_target}")
      redirect_to_url(redirect_target)
    end
  end
  
  def set_content_type_header
    if %w(rss_with_content rss_with_headlines).include?(action_name)
      response.headers['Content-Type'] = 'text/xml; charset=UTF-8'
    else
      response.headers['Content-Type'] = 'text/html; charset=UTF-8'
    end
  end
  
  def set_robots_metatag
    if controller_name == 'wiki' and %w(show published).include? action_name 
      @robots_metatag_value = 'index,follow'
    else
      @robots_metatag_value = 'noindex,nofollow'
    end
  end
  
  def redirect_to_last_url(name, default_redirect_to = {:action => 'index'})
    return_url = session[name]
    if return_url.nil?
      redirect_to default_redirect_to
    else
      redirect_to return_url
    end
  end
  
  def save_url(name)
    session[name] = request.request_uri
  end
  
  def flash_to_cookie
    #MD 13-Feb-2007 Comment out for now until completed
    #cookies['msg_notice'] = {:value => flash[:notice].to_s}
    #cookies['msg_error'] = {:value => flash[:error].to_s}
  end
  
  # The following three methods are used in both attachment_controller and fckeditor_controller  
  def full_directory_name(page, wiki)  
    dir = safe_file_join(MY_CONFIG[:file_upload_root], attachment_directory_name( page, wiki))
    unless dir.starts_with?(File.join(MY_CONFIG[:file_upload_root], MY_CONFIG[:file_upload_top]))
      raise SecurityError, "Path #{dir} not valid"
    end
    FileUtils.mkdir_p(dir)
    return dir 
  end
  
  # Substitute wiki name for %w and page name for %p
  # There might not be a wiki name or page name, so fix double slashes and trailing slashes
  def attachment_directory_name(page, wiki)
    dir = MY_CONFIG[:file_upload_directory].gsub('%w',wiki || '').gsub('%p', page || '').squeeze('/').chomp('/')
    safe_file_join(MY_CONFIG[:file_upload_top], dir)
  end
  
  # Join the file name parts, then check to make sure that nothing funny is going on
  def safe_file_join(*names)
    path = File.join(*names)
    unless File.expand_path(path) == path
      raise SecurityError, "Path #{path} not valid"
    end
    path
  end
  
  #-------------------
  private
  
  DEFAULTS = {:items_per_page => 20, :show_past => false, :show_checked_only => false} unless defined? DEFAULTS
  CLASSES = {:items_per_page => Fixnum, :show_past => TrueClass, :show_checked_only => TrueClass} unless defined? CLASSES
  
  def fix_value(name, value)
    if CLASSES[name] && !value.is_a?(CLASSES[name])
      # Need to_s otherwise it doesn't work
      case CLASSES[name].to_s
      when 'Fixnum'
        value = value.to_i
        
        # Since there is no Boolean class, check if it is TrueClass or FalseClass  
        # If a string, then '0' is false
      when 'TrueClass'
        unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
          if value.is_a?(String)
            value = (value != '0') 
          end  
        end  
      end  
    end  
    value
  end
  
  def fix_name(name)
    if name.is_a?(Symbol)
      name
    else
      name.to_sym
    end  
  end
  
end

module ActionView::Helpers::AssetTagHelper
  
  def theme_dir
    'themes/' + @wiki.config[:theme]
  end
  
  def theme_path(source, sub_dir)
    path = source
    unless source.first == "/" || source.include?(":")
      if File.exists?(File.join(RAILS_ROOT, 'public', 'files', @wiki.name, source))
        path = File.join('/files', @wiki.name, source)
      elsif !@wiki.config[:theme].blank? && 
        File.exist?(File.join(RAILS_ROOT, 'public', theme_dir, sub_dir, source))
        path = File.join('/' + theme_dir, sub_dir, source)
      end
    end
    path
  end
  
  alias_method :image_path_orig, :image_path unless method_defined?(:image_path_orig)
  def image_path(source)
    image_path_orig(theme_path(source,'images'))
  end    
  
  def file_path(source)
    theme_path(source,'files')
  end    
  
end


