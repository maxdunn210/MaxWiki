require 'fileutils'
require 'redcloth_for_tex'
require 'parsedate'
require 'zip/zip'
require 'resolv'

class WikiController < ApplicationController
  
  after_filter :cache_wiki_page, :only => [:show]
  cache_sweeper :revision_sweeper
  before_filter :authorize_page_read, :only => [:pdf, :print, :published, :show, :revision]
  # Authorization for "new" is checked in the method itself
  before_filter :authorize_page_write, :only => [:edit, :cancel_edit, :locked, :save, :rollback]
  before_filter :authorize_admin, :only => [:delete_page]
  
  layout 'main', :except => [:rss_feed, :rss_with_content, :rss_with_headlines, :export_html]
  include WikiHelper
  include CacheHelper
  
  # Outside a single wiki  --------------------------------------------------------
  
  def login
    # to template
  end
  
  # Within a single wiki ---------------------------------------------------------
  
  def authors
    parse_pages
    @page_names_by_author = @wiki.page_names_by_author
    
    authorized_page_names = @wiki.page_names
    @page_names_by_author.each {|key, value| @page_names_by_author[key] &= authorized_page_names }
    @authors = @page_names_by_author.keys.sort
  end
  
  def export_html
    #MD debug # stylesheet = File.read(stylesheet_path('styles.css'))
    stylesheet = ''
    export_pages_as_zip('html') do |page| 
      
    rendered_page = <<-EOL
      
        <!DOCTYPE html
        PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
        <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
          <title>#{page.plain_name} in #{@wiki.description}</title>
          <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  
          <style type="text/css">
            h1#pageName, .new_wiki_word a, a.existingWikiWord, .new_wiki_word a:hover { 
              color: ##{@wiki ? @wiki.color : "393" }; 
            }
            .new_wiki_word { background-color: white; font-style: italic; }
            #{stylesheet}
          </style>
          <style type="text/css">
            #{@wiki.additional_style}
          </style>
        </head>
        <body>
          #{page.display_content_for_export}
          <div class="byline">
            #{page.revisions? ? "Revised" : "Created" } on #{ page.revised_at.strftime('%B %d, %Y %H:%M:%S') }
            by
            #{ @wiki.make_link(page.author.name, nil, { :mode => :export }) }
          </div>
        </body>
        #{''}</html>      
      EOL
      
      rendered_page
    end
  end
  
  def export_markup
    export_pages_as_zip(@wiki.markup) do |page| 
      page.content
    end  
  end
  
  def feeds
    parse_pages
    @rss_with_content_allowed = rss_with_content_allowed?
    # show the template
  end
  
  def index
    redirect_to :controller => 'wiki', :action => 'list'
  end
  
  def list
    parse_pages
  end
  
  def orphan
    parse_pages
    @pages_that_are_orphaned = @all_pages.orphaned_pages
  end

  def wanted
    parse_pages
    @page_names_that_are_wanted = @pages.wanted_pages
  end

  def recently_revised
    parse_pages
    @pages_by_revision = @all_pages.by_revision
  end
  
  def rss_with_content
    if rss_with_content_allowed?
      render_rss(hide_description = false, *parse_rss_params)
    else
      render_text 'RSS feed with content for this wiki is blocked for security reasons. ' +
        'The wiki is password-protected and not published', '403 Forbidden'
    end
  end
  
  def rss_with_headlines
    render_rss(hide_description = true, *parse_rss_params)
  end
  
  def search
    @query = params['query']
    @title_results = @wiki.select { |page| page.name =~ /#{@query}/i }.sort
    @results = @wiki.select do |page| 
      begin
        page.content =~ /#{@query}/i
      rescue
        logger.error "Page #{page.name} in wiki #{@wiki.name} doesn't have any content!"
        false
      end
    end.sort
    all_pages_found = (@results + @title_results).uniq
  end
    
  # Within a single page --------------------------------------------------------
  
  def cancel_edit
    @page.unlock
    redirect_to_page(main_page_link(@page))
  end
  
  def edit 
    if @page.new_record?
      redirect_to :action => 'new', :link => @page.link, :page_name => @page.name
      return
    end
    
    if @page.locked?(Time.now) and not params['break_lock']
      
      # Using "editor_1" is to correct for a weird bug in Rails 1.2.1
      # If we try to set the parameter :editor here, the url generated ignores it
      # It seems like somehow routes are remembering that :editor was used to come here, and then
      # stripping it off of any generated URLs. So using a different parameter is to work around this bug.    
      redirect_to :action => 'locked', :link => @page.link, :editor_1 => @editor
    else
      setup_roles
      @page.lock(Time.now, @author)
    end
    
    setup_page_content_and_type(@page.revisions.last) 
  end
  
  def locked
    # to template
  end
  
  ACCESS_DEFAULTS = {:access_read => ROLE_PUBLIC,
    :access_write => ROLE_EDITOR, 
    :access_permissions => ROLE_ADMIN} unless defined?(ACCESS_DEFAULTS)
  
  # Most methods user before_filter to authorize them. However for "new" there is
  # no page yet, so we can't check against the defaults. So setup the page first and
  # the access defaults, then check authorization
  def new
    setup_roles
    
    unless @page.new_record?
      redirect_to :action => 'edit', :link => @page.link, :editor_1 => params[:editor]
      return
    end
    
    return unless authorize_page_write
    
    parent_link = params[:parent_link]
    unless parent_link.blank?
      @page.parent = @wiki.read_page_by_link(parent_link)
    end
    @page.kind = params[:kind] if @page.kind.blank?
    
    setup_page_content_and_type(nil) 
    render :controller => 'wiki', :action => 'edit', :link => @page.link
  end
  
  def revision
    setup_revision
  end
  
  def rollback
    setup_revision
    setup_roles
    setup_page_content_and_type(@revision)
    
    render :controller => 'wiki', :action => 'edit', :link => @page.link
  end
  
  # If there is an existing page, @page will be set
  # If the page link is passed in params[:link], either for new or existing, @page.link will be set
  # Params[:page_name] is used to provide the name of a new page or rename an existing page
  def save
    cookies['author'] = { :value => params['author'], :expires => Time.utc(2030) }
    begin
      # First check for blank page name
      raise ArgumentError, "Please enter a page name" if @page.link.blank? && @page.name.blank?
      
      parent_name = params['page_parent'] rescue ''
      kind = params['page']['kind'] rescue nil
      access = {}
      permissions = @page.nil? ? ACCESS_DEFAULTS : @page.access_permissions
      if !params['page'].nil? && Role.check_role(permissions)
        access = {:access_read => params['page']['access_read'],
          :access_write => params['page']['access_write'], 
          :access_permissions => params['page']['access_permissions']}
      end

        # Existing page
      unless @page.new_record?
        if params['content']
          @page.revise(params['content'], params['content_type'], parent_name, access,
          Time.now, Author.new(params['author'], remote_ip), kind)
        end
        
        # Page renamed. Check for existing page with same name, update the wiki references, expire the cache and rename the page
        new_page_name = params[:page_name]
        if !new_page_name.blank? && (new_page_name != @page.name)
          check_existing_page(new_page_name)
          expire_page_and_affected(@page)
          old_page_name = @page.name
          @page.rename(new_page_name)
          WikiReference.rename_page(old_page_name, new_page_name) # This needs to go after @page.rename in case there is an exception
        end
                  
        # Check if page link renamed
        # If page_link is present but empty, regenerate a new link
        new_page_link = params[:page_link]
        unless new_page_link.nil?
          if new_page_link.empty?  
            new_page_link = Page.create_link(@page.name)
          end          
          if new_page_link != @page.link
            check_existing_page_link(new_page_link)
            expire_page_and_affected(@page)
            @page.rename_link(new_page_link)
          end
        end
        
        @page.unlock
        
      # New page  
      else
        check_existing_page(@page.name)
        return if !authorize_page_write
        @page.revise(params['content'], params['content_type'], parent_name, access,
        Time.now, Author.new(params['author'], remote_ip), kind)
      end
      
      save_direct_css
      redirect_to_page main_page_link(@page)
    rescue => e
      # This makes debugging easier
      raise if RAILS_ENV == 'development'
      
      flash[:error] = e
      logger.error e
      flash[:content] = params['content']
      if @page.new_record?
        redirect_to :action => 'new', :link => @page.link, :page_name => @page.name
      else
        @page.unlock 
        redirect_to :action => 'edit', :link => @page.link
      end
    end
  end
    

  # autosave
  # 
  # Uses ajaxAutoSave
  # Don't rename or save any other parameters. Just save another copy over the existing one
  # 
  # Must return:
  # e.g. success :
  #    <?xml version="1.0" encoding="UTF-8"?> <adapter command="save" > <result message="success" /> </adapter> 
  # e.g. error :
  #    <?xml version="1.0" encoding="UTF-8"?> <adapter command="save" > <error errorNumber="101" errorData=""/> </adapter> 
  #
  # Predefined errornumbers are:
  #   0: No error
  # 101: No content received by server
  # 102: Couldn't connect to database
  # 103: Query error
  # 104: Bad XML response
  # 105: XML Request error
  def autosave
    if @page.new_record?
      @error = 103
    else
      @error = 0
      @page.autosave(params['content'])
      save_direct_css
     end         
     
     respond_to do |format|
      format.xml { render :layout => false }
    end
  end
  
  def print
    render :action => 'page', :layout => 'simple'
    end

    def show
      unless @page.new_record?
        begin
          @left_column_name, @left_column_page = setup_col('_left')
        @right_column_name, @right_column_page = setup_col('_right')
        @left_column_show = !MY_CONFIG[:hide_empty_left_column] || !@left_column_page.nil?
        @right_column_show = !MY_CONFIG[:hide_empty_right_column] || !@right_column_page.nil?
        
        if @left_column_show && @right_column_show
          @middle_column_size = 'narrow'
        elsif @left_column_show || @right_column_show
          @middle_column_size = 'wide'
        else
          @middle_column_size = 'full'
        end
        
        render :action => 'page'
        
        # TODO this rescue should differentiate between errors due to rendering and errors in 
        # the application itself (for application errors, it's better not to rescue the error at all)
      rescue => e
        #MD Debug
        #raise
        logger.error e
        flash[:error] = e.message
        if Role.check_role(@page.access_write)
          redirect_to :action => 'edit', :link => @page.link
        else
          raise e
        end
      end
    else
      if @page.link.blank?
        render(:text => 'Page is not specified', :status => 404)
      elsif !Role.check_role(ROLE_EDITOR)
        render :action => 'not_found', :status => 404
      else
        redirect_to :action => 'new', :link => @page.link, :page_name => @page.name
      end
    end
  end
  
  def delete_page
    if params[:page] 
      @wiki.remove_page_by_name(params[:page])
    elsif params[:before] 
      @wiki.remove_pages_before(params[:before])
    elsif params[:after] 
      @wiki.remove_pages_after(params[:after])        
    end
    
    redirect_to :action => params[:return_to]
  end    
      
  #------------------------  
  protected
  
  def wiki_access_denied(access_attempted, needed_role, page_name)
    @access_attempted = access_attempted
    @needed_role = needed_role
    @current_role = session_role
    @page_name = page_name
    render :action => 'access_denied', :status => 401
  end
  
  def authorize_page_write
    unless Role.check_role(@page.access_write)
      wiki_access_denied(:write, @page.access_write, @page.name)
      false
    else
      true
    end
  end
  
  # We need the check for @page.nil? here because if we are setting up the system or the wiki
  # @page won't be setup yet but this will still be triggered
  def authorize_page_read
    unless @page.nil? || Role.check_role(@page.access_read)
      wiki_access_denied(:read, @page.access_read, @page.name)
      false
    else
      true  
    end
  end
  
  def setup_col(suffix)
    if MY_CONFIG[:menu_on_left] && suffix == '_left' &&
      !(MY_CONFIG[:menu_in_header_buffer_on_home_page] && @page.name == 'HomePage')  &&
      (@page.parent.blank? && @wiki.read_page(@page.name + suffix).blank?)  # If a left menu, or a child, don't show main menu
      col_name = MY_CONFIG[:layout_sections][1] # 'menu'
    elsif suffix == '_left' && !@page.parent.blank?
      col_name = @page.parent.name + suffix
    else
      col_name = @page.name + suffix
    end
    col_page = @wiki.read_page(col_name)
    return col_name, col_page
  end
  
  def connect_to_model
    super
    
    # Setup system if necessary
    # Do it here rather than application to prevent recursive calls
    if @system.nil?
      redirect_to :controller => 'admin', :action => 'create_system'
      return true
    end
    
    # Setup wiki if necessary
    if @wiki.nil?
      redirect_to :controller => 'admin', :action => 'create_wiki'
      return true
    end
    
    # Clear out @page. Needed because of Mongrel object caching
    @page = nil
    
    # Search for the page, first look at link then look at name
    # If redirect needed, will return a string
    page_link = params[:link]
    result = search_for_page(page_link)
    if result.is_a?(String)
      redirect_to("/#{result}") #Pass in a string rather than hash so it won't CGI.unescape the page name
      return true
    end 
    @page = result
    
    # If we can't find the page, create a new one. 
    if @page.nil?
      @page = Page.new(ACCESS_DEFAULTS)  
      if params[:page_name].blank?
        @page.name = page_link
        @page.link = Page.create_link(@page.name)
      else  
        @page.link = page_link
        @page.name = params[:page_name] #CGI.unescape(params[:page_name]) 
        end  
        @page_name = @page.name if @page_name.blank? 
      end

      # Assign this so Revision knows what the main page name is. Used for menus
      MaxWikiActiveRecord.current_page_link = @page.link

      # Setup editor to use on this page.
    page_editor = nil
    if !@page.new_record?
      if @page.revisions.last.content_type == :textile && 
        (@wiki.config[:editor].nil? || @wiki.config[:editor].downcase != 'wysiwyg')
        page_editor = 'textile'
      else
        page_editor = 'wysiwyg'
      end
    end
    @editor = (params[:editor] || params[:editor_1] || page_editor || @wiki.config[:editor] || 'textile').downcase
    
    return true #Needed or WEBrick doesn't show anything if last result is nil
  end
        
  #-------------------------
  private
  
  # If pagename is "direct_css" then save as css file
  def save_direct_css
    if @page.name == 'direct_css'
      dir_name = full_directory_name('', @wiki.name)
      name_with_dir = safe_file_join(dir_name, 'direct.css')
      stripped_content = @page.content.gsub(%r{</?[^>]+?>},'').gsub('&nbsp;',' ').gsub("\t",'')
      File.open(name_with_dir, 'wb', 0664) do |f|
        f.write(stripped_content)
      end
    end
  end
  
  
  # Parameter page_link (from params[:link]) will always be decoded using CGI.unescape
  # This means that + will be converted to space and all % signs will be translated to symbols
  # like %20 will be translated to space
  # The problem is that the pages are cached with their link name, which may include a + sign
  # and we want to redirect to the link name so that the cached page will be used.
  # However, if a link name comes in with a space, we don't know if it was passed as a + or a %20
  # so we need to look at the original request to see what was really passed
  def search_for_page(page_link)
    return nil if page_link.blank?
    
    # Check if link is a paged blog, if so strip off prefix and save page number
    page_number = nil 
    page_link, page_number = Page.parse_page(page_link)
    
    # Try reading first by link
      page = @wiki.read_page_by_link(page_link) 

      # Now try finding by name
    if page.nil? 
      page = @wiki.read_page(page_link) 
    end
    
    # if not found, then try by unencoded link
    if page.nil? 
      page = @wiki.read_page_by_link(CGI.unescape(page_link)) 
    end
    if page.nil? 
      page = @wiki.read_page(CGI.unescape(page_link))
    end
    
    # Add the page number
    page.page_number = page_number unless page.nil?
    
    # Return if page not found or if the action is not show
    return page if page.nil? || params[:action] != 'show'

      # Parse the actual request to get the path, stripping off the leading /
    # If there is a problem parsing the request, then just return the page found
    uri_path = URI.parse(request.request_uri).path rescue nil
    return page if uri_path.nil?
    
    # Grab the last element after the slash and take out page number if present
    slash_pos = uri_path.rindex('/')
      slash_pos = -1 if slash_pos.nil?
      actual_link = Page.strip_page(uri_path.slice(slash_pos + 1, 255))

      # If redirect not needed, return the page
    if (page.link == actual_link) || (page.link == 'homepage' && actual_link == '')
        return page
      end

      # Redirect adding page number if necessary
    return page.link_with_page_number
  end
  
  def check_existing_page(page_name)
    raise ArgumentError, 'There is already a page with that name. Please use another name' if @wiki.has_page?(page_name)
  end
  
  def check_existing_page_link(page_link)
    raise ArgumentError, 'There is already a page with that permalink. Please use another permalink' if @wiki.has_page_link?(page_link)
  end
  
  def setup_page_content_and_type(revision)
    # If using the WYSIWGY editor, don't show the textile help    
    if @editor != 'textile'
      @middle_column_size = 'full'
      @left_column_show = FALSE
    end  
    
    # Setup page list for parent page dropdown
    parse_pages
    
    # New page
    if revision.nil?
      @page_content = ''
      if @editor == 'textile'
        @page_content_type = 'textile'
      else
        @page_content_type = 'html'
        end
        return
      end

      # Existing page            
    if revision.content_type == :textile && @editor != 'textile'
      @page_content = convert_textile_to_html(revision)
      @page_content_type = 'html'
    else
      @page_content = revision.content
      
      # If opening a page in the textile editor, force it to a textile type so textile codes will be processed
      if @editor == 'textile'
        @page_content_type = :textile
      else
        @page_content_type = revision.content_type
      end
    end
  end
  
  # Convert textile code into html for use in a WYSIWYG editor
  # Most erb commands will be left alone, but change "link_to" commands to html equivalents
  def convert_textile_to_html(revision)    
    safe_cmds = ['link_to', 'image_tag']
    link_to_re = /<%=\s*link_to.*?%>/mi
    av = ActionView::Base.new(base_path = self.class.view_paths, assigns_for_first_render = {}, controller = self)
    av.instance_variable_set("@wiki", @wiki)
    av_binding = av.send('binding')
    
    html = revision.display_content(:render_for_edit => true)
    fix_double_quotes(html)
    html.gsub(link_to_re) do |match| 
      ERbLight.new(match, safe_cmds, nil).result(av_binding)
    end      
  end
  
  def export_pages_as_zip(file_type, &block)
    
    file_prefix = "#{@wiki.name}-#{file_type}-"
    timestamp = @wiki.revised_at.strftime('%Y-%m-%d-%H-%M-%S')
    file_path = File.join(@system.storage_path, file_prefix + timestamp + '.zip')
    tmp_path = "#{file_path}.tmp"
    
    Zip::ZipOutputStream.open(tmp_path) do |zip_out|
      @wiki.select.by_name.each do |page|
        if Role.check_role(page.access_read)
          zip_out.put_next_entry("#{CGI.escape(page.name)}.#{file_type}")
          zip_out.puts(block.call(page))
        end  
      end
      # add an index file, if exporting to HTML
      if file_type.to_s.downcase == 'html'
        zip_out.put_next_entry 'index.html'
        zip_out.puts "<html><head>" +
          "<META HTTP-EQUIV=\"Refresh\" CONTENT=\"0;URL=HomePage.#{file_type}\"></head></html>"
      end
    end
    FileUtils.rm_rf(Dir[File.join(@system.storage_path, file_prefix + '*.zip')])
    FileUtils.mv(tmp_path, file_path)
    send_file file_path
  end
  
  def setup_revision
    @revision_number = params['rev'].to_i
    @revision = @page.revisions[@revision_number]
  end
  
  def parse_pages
    page_filter = params.include?('all') ? :all_pages : :main_and_layout_pages 
    @pages = @wiki.select_all(page_filter).by_name
    authorized_pages!(@pages)
    
    if page_filter == :all_pages
      @all_pages = @pages
    else
      @all_pages = @wiki.select_all(:all_pages).by_name
      authorized_pages!(@all_pages)
    end
    @set_name = 'this site'
  end
              
  def parse_rss_params
    if params.include? 'limit'
      limit = params['limit'].to_i rescue nil
    limit = nil if limit == 0
    else
      limit = 15
    end
    start_date = Time.local(*ParseDate::parsedate(params['start'])) rescue nil
  end_date = Time.local(*ParseDate::parsedate(params['end'])) rescue nil
  [ limit, start_date, end_date ]
  end
  
  def remote_ip
    ip = request.remote_ip
    logger.info(ip)
    ip.gsub!(Regexp.union(Resolv::IPv4::Regex, Resolv::IPv6::Regex), '\0') || 'bogus address'
  end
  
  def render_rss(hide_description = false, limit = 15, start_date = nil, end_date = nil)
    if limit && !start_date && !end_date
      @pages_by_revision = @wiki.select(:main_pages).by_revision.first(limit)
    else
      @pages_by_revision = @wiki.select(:main_pages).by_revision
      @pages_by_revision.reject! { |page| page.revised_at < start_date } if start_date
      @pages_by_revision.reject! { |page| page.revised_at > end_date } if end_date
    end
    
    @hide_description = hide_description
    @link_action = 'show'
    
    render :action => 'rss_feed'
  end
  
  def rss_with_content_allowed?
    true
  end
  
  def truncate(text, length = 30, truncate_string = '...')
    if text.length > length then text[0..(length - 3)] + truncate_string else text end
  end
  
  def main_page_link(page)
    if page.name =~ /(.*)(_left|_right)$/
      Page.find_by_name($1).link rescue page.link
    else  
      page.link
    end  
  end
  
  def cache_wiki_page
    unless @page.nil? ||
      response.body =~ /#{no_cache}/ || 
      !Role.roles_equal?(@page.access_read, ROLE_PUBLIC)
      if @page.link == 'homepage'
        cache_name = 'index'
      else
        cache_name = @page.link_with_page_number
      end
      cache_page(response.body,{:link => cache_name})
    end  
  end
  
  def setup_roles
    @roles = WikiConfig.roles
  end
  
  # Change double-quotes to single-quotes in tags so tests won't have parsing problems in WYSIWYG mode
  # running ruby test/functional/wiki_controller_test.rb -n test_content_wysiwyg
  def fix_double_quotes(html)
    html.gsub!(/<[^>]*>/m) { |tag| tag.gsub(%q{"}, %q{'}) }
  end  

end
