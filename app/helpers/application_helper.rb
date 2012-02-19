# The methods added to this helper will be available to all templates in the application.

name = "#{RAILS_ROOT}/config/local_helper.rb"
require name if File.exist?(name)

module ApplicationHelper
  
  include WikiHelper
  include LocalHelper rescue nil
include ThemeHelper rescue nil
include WebdavHelper
  include GoogleMapHelper
  include AuthorizationHelper
  include SurveysHelper
  include PlayerHelper
  
  def self.to_yesno(bool)
    if bool 
      'Yes' 
    else 
      'No'
    end
  end
  
  def list_edit_link(name, options)
    # The "name" parameter should be protected by h(name)
    # However, for dates, we want to put the day on a separate
    # line by using <br /> so we are turning it off here
    # Would be nice if there was a function to strip any dangerous
    # HTML but leave simple tags
    # The calling function should use h() on the name parameter before passing it
    # if it could be dangerous
    display_name = name.to_s.strip.empty? ? '(Blank)' : name
    if Role.check_role(ROLE_EDITOR)
      link_to display_name, options
    else
      display_name
    end
  end
  
  def wiki_link(page, name = '', html_class = '')
    name = page if name.nil? or name.empty?
    
    if html_class.nil? or html_class.empty?
      html_class_hash = {}
    else
      html_class_hash = {:class => html_class} 
    end  
    
    if page.class == Hash
      link_to_hash = page
    else      
      link = @wiki.read_page(name).link rescue nil
      link_to_hash = {:controller => "wiki", :action => "show", :link => link}
    end
    link_to( name, link_to_hash, html_class_hash)
  end
  
  def page_link(display_name, page_name = nil)
    return '' if display_name.blank?
    page_name = display_name if page_name.nil?
    link_to_page(page_name, @wiki, display_name) 
  end
  
  # Pass in the name of an action, or a regex with multiple names like "new|create" and if the current action matches these,
  # then the li tag will be returned with the id element so the user will know what page they are currently on.
  # If a wiki page, look for an exact match unless there are regex characters
  def action_match(action_names)
    if controller.controller_name == 'wiki' && controller.action_name == 'show'
      if action_names =~ /\*|\?|\|/ then 
        params[:link] =~ /#{action_names}/i
      else 
        params[:link] == action_names
      end
    else
      "#{controller.controller_name}-#{controller.action_name}" =~ /#{action_names}/i
    end
  end
  
  def tag_li(action_names, tag)
    if action_match(action_names)
      "<li #{tag}>"
    else
      '<li>'
    end
  end
  
  #MD Debug 10/9/2006
  #alias_method :tag_li_selected, :tag_li_current
  def tag_li_current(action_names)
    tag_li_selected(action_names)
  end
  
  def tag_li_selected(action_names)
    tag_li(action_names, 'class="selected"')
  end
  
  def tag_href_selected(name, page='' , action_names='', image_marker = '' )
    page = name if page.nil? or page.empty?
    action_names = page if action_names.nil? or action_names.empty?
    if action_match(action_names)
      selected = 'selected'
    else
      selected = nil
    end
    
    if image_marker.blank?
      image_and_name = name
    else
      image_and_name = image_tag(image_marker) + name
    end
    
    wiki_link(page, image_and_name, selected)
  end
  
  def tag_li_href_selected(name, page='', action_names='', image_marker = '')
    '<li>' + tag_href_selected(name, page, action_names, image_marker) + "</li>\n"
  end
  
  PREVIOUS = '< Previous' unless defined? PREVIOUS
  NEXT = 'Next >' unless defined? NEXT
  
  def pagination_template(pages, options = {})
    html = ''
    html << "<br />" unless options[:suppress_spacing]
    if pages && pages.previous_page
      html << link_to(PREVIOUS, { :page => pages.previous_page })
    else
      html << "<u>#{PREVIOUS}</u>"
    end  

    if pages
      html << " (#{pages.current_page} of #{pages.total_pages}) "
    else
      html << " (0 of 0) "
    end
    
    if pages && pages.next_page
      html << link_to(NEXT, {:page => pages.next_page})
    else
      html << "<u>#{NEXT}</u>"
    end  
    html << "\n"
    
    html << form_tag({:controller => 'register', :action => 'update_list_filters'})
    html << '&nbsp;Lines per page:'
    html << text_field('register', 'items_per_page', "size" => 3, "value" => session_get(:items_per_page))
    html << '&nbsp;&nbsp;'
    if options[:show_checked_only]
      checked = "checked" if session_get(:show_checked_only)
      html << 'Show checked only'
      html << check_box('register', 'show_checked_only', :checked => checked)
      html << '&nbsp;'
    end
    if options[:show_past]
      checked = "checked" if session_get(:show_past)
      html << 'Show past dates:'
      html << check_box('register', 'show_past', :checked => checked)
      html << '&nbsp;'
    end
    html << submit_tag('Go')
    html << end_form
    html << "\n"
    html << "<br />\n<br />\n" unless options[:suppress_spacing]
    html
  end
  
  def blog_pagination(pages, link)
    html = ''
    html << "<br />\n"

    if pages && pages.previous_page
      html << link_to(PREVIOUS, {:link => Page.link_with_page_number(link, pages.previous_page)})
    else
      html << "<u>#{PREVIOUS}</u>"
    end  
    if pages
      html << " (#{pages.current_page} of #{pages.total_pages}) "
    else
      html << " (0 of 0) "
    end
    
    if pages && pages.next_page
      html << link_to(NEXT, {:link => Page.link_with_page_number(link, pages.next_page)})
    else
      html << "<u>#{NEXT}</u>"
    end  

    html << "\n<br />\n<br />\n"
    html
  end
  
  def xml_encode(text)
    text.unpack('c*').map{|c|"&\##{c};"}.join
  end
  
  def url_encode(text)
    text.split('').map{|c|"%#{c.unpack('H2')}"}.join
  end
  
  def encode_email(email)
    encoded_email = url_encode(email)
    encoded_mailto = xml_encode("mailto:" + encoded_email)
    mangled_email = email.gsub!(/@/, ' at ').gsub!(/\./, ' dot ')
    "<a href=\"#{encoded_mailto}\">#{mangled_email}</a>"
  end   
  
  def safe_cmds
    ['image_path', 'file_path', 'link_to', 'render', 
     '@title', 'image_tag', 'true', 'false', 
     '@level_both', '@level_business', '@level_personal'] + 
    ApplicationHelper.public_instance_methods
  end
  
  def render_with_erb(content)  
    ERbLight.new(content, safe_cmds, nil).result(binding)
  end  
  
  def render_layout_section(name)
    if @layout_section_pages[name].nil?
      content = "'#{name}' page not found"
    else   
      display_content = @layout_section_pages[name].display_content
      content = render_with_erb(display_content)
    end 	
    content
  end	
  
  def include(name)
    page = Page.find_by_name(name)
    if page.nil?
     "Page '#{name}' not found"
    else
      render_with_erb(page.display_content)
    end
  end
  
  def render_layout_edit_links(name)
    render(:partial => 'layouts/edit_links', :locals => {:edit_page => @layout_section_pages[name], :edit_name => name})
  end  
  
  def role_script
    <<-EOF
    <script type='text/javascript'>
    var func = function() {
      if (readCookie('role') == '#{ROLE_ADMIN}') {
        showClass('role_#{ROLE_ADMIN}');
        showClass('role_#{ROLE_EDITOR}');
        showClass('role_#{ROLE_USER}');
        showClass('role_#{ROLE_PUBLIC}');
      } else if (readCookie('role') == '#{ROLE_EDITOR}') {
        showClass('role_#{ROLE_EDITOR}');
        showClass('role_#{ROLE_USER}');
        showClass('role_#{ROLE_PUBLIC}');
      } else if (readCookie('role') == '#{ROLE_USER}') {
        showClass('role_#{ROLE_USER}');
        showClass('role_#{ROLE_PUBLIC}');
      } else  {
        showClass('role_#{ROLE_PUBLIC}');
        showClass('role_none');
      }
    }
    onloadInit();
    onloadAdd(func);
    </script>
    EOF
  end  
  
  def config_site_name
    @wiki.config[:site_name]
  end
  
  def session_user_name
    su = session[:user]
    su.nil? ?  'Not Logged In' : "#{su[:firstname]} #{su[:lastname]}" 
  end
  
  def session_role_name
    Role.role_name(session_role)
  end
  
  def check_cookies
    role = cookies['role']
    return nil if role.nil?
    if role.is_a?(String)
      role == session_role
    else
      role.first == session_role
    end
  end
  
  #MD Debug. This is a hack, take out as soon as possible
  # The problem is that delivery_method is a global variable, and so it
  # could mess up a batch processing taking place at the same time
  def deliver_now
    save_delivery_method = ActionMailer::Base.delivery_method
    ActionMailer::Base.delivery_method = :smtp unless save_delivery_method == :test
    yield
    ActionMailer::Base.delivery_method = save_delivery_method    
  end
  
  def revision_link
    if @page.new_record? || @page.revisions.length < 2
      'Created'
    else  
      rev_to_show =  @page.revisions.length - 1
      rev_to_show = 0 if rev_to_show < 0
      link_to("Revised", 
      {:controller => 'wiki', 
        :action => 'revision', :link => @page.link, 
        :rev => rev_to_show})
    end
  end
  
  def drag_map_javascript(drag_map)
    html = "\n<script type=\"text/javascript\">\n"
    html << "//<![CDATA[\n"
    html << "mapArray.length = 0\n"
    if drag_map
      key = 1
      drag_map.each do |key, value|
        html << "mapArray[#{key}] = #{value}\n"
      end
    end  
    html << "//]]>\n"
    html << "</script>\n"
    html
  end
  
  # In Rails 1.2, end_form_tag has been deprecated. The replacements is to use 'form_tag ... do' and 'end'
  # However, this doesn't work in previous versions. So this is for compatibility between the two.
  def end_form
    '</form>'
  end
  
  def user_info_incomplete
    @user.lastname.blank? || @user.firstname.blank?
  end
  
  def maintenance_msg
    MaxWikiActiveRecord.system_read_only_mode ? MaxWikiActiveRecord.system_read_only_msg : ''
  end
  
  def favicon_link_tag
    favicon_name = ['favicon.ico','favicon.gif','favicon.png'].find do |name| 
      File.exists?("#{RAILS_ROOT}/public/files/#{@wiki.name}/#{name}")
    end
    return '' if favicon_name.nil?
    
    %Q{<link rel="shortcut icon" href="/files/#{@wiki.name}/#{favicon_name}" />}
  end
  
  def maxwiki_stylesheet_link_tags
    html = stylesheet_link_tag("main.css", :media => "all") + "\n"
    unless @wiki.config[:theme].blank?
      if File.exist?("#{RAILS_ROOT}/public/themes/#{@wiki.config[:theme]}/stylesheets/theme.css")
        html << stylesheet_link_tag("/themes/#{@wiki.config[:theme]}/stylesheets/theme.css", :media => "all") + "\n"
      end
      if File.exist?("#{RAILS_ROOT}/public/themes/#{@wiki.config[:theme]}/stylesheets/theme_print.css")
        html << stylesheet_link_tag("/themes/#{@wiki.config[:theme]}/stylesheets/theme_print.css", :media => "print") + "\n"
      end      
    end  
    
    unless @wiki.name.blank?
      if File.exist?("#{RAILS_ROOT}/public/files/#{@wiki.name}/site.css")
        html << stylesheet_link_tag("/files/#{@wiki.name}/site.css", :media => "all") + "\n"
      end
      if File.exist?("#{RAILS_ROOT}/public/files/#{@wiki.name}/site_print.css")
        html << stylesheet_link_tag("/files/#{@wiki.name}/site_print.css", :media => "print") + "\n"
      end
      if File.exist?("#{MY_CONFIG[:file_upload_root]}#{MY_CONFIG[:file_upload_top]}/#{@wiki.name}/direct.css")
        html << stylesheet_link_tag("#{MY_CONFIG[:file_upload_top]}/#{@wiki.name}/direct.css", :media => "all") + "\n"
      end

    end

    # Put this last to override the other styles so FF prints correctly
    if File.exist? "#{RAILS_ROOT}/public/stylesheets/main_print.css"
      html << stylesheet_link_tag("main_print.css", :media => "print") + "\n"
    end
    
    html  
  end
  
  
  #---- Stuff from Instiki helper. Needs cleanup. Not all of it is still used -----
  
  # Accepts a container (hash, array, enumerable, your type) and returns a string of option tags. Given a container 
  # where the elements respond to first and last (such as a two-element array), the "lasts" serve as option values and
  # the "firsts" as option text. Hashes are turned into this form automatically, so the keys become "firsts" and values
  # become lasts. If +selected+ is specified, the matching "last" or element will get the selected option-tag.
  #
  # Examples (call, result):
  #   html_options([["Dollar", "$"], ["Kroner", "DKK"]])
  #     <option value="$">Dollar</option>\n<option value="DKK">Kroner</option>
  #
  #   html_options([ "VISA", "Mastercard" ], "Mastercard")
  #     <option>VISA</option>\n<option selected>Mastercard</option>
  #
  #   html_options({ "Basic" => "$20", "Plus" => "$40" }, "$40")
  #     <option value="$20">Basic</option>\n<option value="$40" selected>Plus</option>
  def html_options(container, selected = nil)
    container = container.to_a if Hash === container
    
    html_options = container.inject([]) do |options, element| 
      if element.respond_to?(:first) && element.respond_to?(:last)
        if element.last != selected
          options << "<option value=\"#{element.last}\">#{element.first}</option>"
        else
          options << "<option value=\"#{element.last}\" selected>#{element.first}</option>"
        end
      else
        options << ((element != selected) ? "<option>#{element}</option>" : "<option selected>#{element}</option>")
      end
    end
    
    html_options.join("\n")
  end
  
  # Creates a hyperlink to a Wiki page, without checking if the page exists or not
  def link_to_existing_page(page, text = nil, html_options = {})
    link_to(
            text || page.plain_name, 
            {:action => 'show', :link => page.link, :only_path => true},
    html_options)
  end
  
  # Creates a hyperlink to a Wiki page, or to a "new page" form if the page doesn't exist yet
  def link_to_page(page_name, wiki= @wiki, text = nil, options = {})
    raise 'Wiki not defined' if wiki.nil?
    wiki.make_link(page_name, text, 
                   options.merge(:base_url => "#{base_url}/#{wiki.name}"))
  end
  
  def author_link(page, options = {})
    page.wiki.make_link(page.author.name, nil, options)
  end
  
  def creator_link(page, options = {})
    page.wiki.make_link(page.revisions[0].author.name, nil, options)
  end
  
  def base_url
    home_page_url = url_for :controller => 'admin', :action => 'create_system', :only_path => true
    home_page_url.sub(%r-/create_system/?$-, '')
  end
  
  # Performs HTML escaping on text, but keeps linefeeds intact (by replacing them with <br/>)
  def escape_preserving_linefeeds(text)
    h(text).gsub(/\n/, '<br/>')
  end
  
  def format_date(date, include_time = true)
    return '' if date.nil?
    # Must use DateTime because Time doesn't support %e on at least some platforms
    date_time = DateTime.new(date.year, date.mon, date.day, date.hour, date.min, 
                             date.sec)
    if include_time
      return date_time.strftime("%B %e, %Y %H:%M:%S")
    else
      return date_time.strftime("%B %e, %Y")
    end
  end
  
  def flash_cookie_tag(cookie, klass = nil)
    klass = cookie if klass.blank?
    
    <<-EOF 
    <div id='#{cookie}' class='#{klass}' style="display:none"></div>
    
    <script type='text/javascript'>
      var func = function() {
        var error_msg = readCookie('#{cookie}')
        if (error_msg) {
          var elem = document.getElementById('#{cookie}');
          elem.innerHTML = simpleUnescape(error_msg);
          elem.style.display = 'block';
          eraseCookie('#{cookie}');
        }
      }
      onloadAdd(func);
    </script>  
    EOF
  end
  
end  

#---------------------------
module ActionView::Helpers::ActiveRecordHelper
  
  alias_method :error_messages_for_old, :error_messages_for unless method_defined?(:error_messages_for_old)
  def error_messages_for(*params)
    error_messages_for_old(params, {:class => 'msg_error', :id => nil})
  end
end


