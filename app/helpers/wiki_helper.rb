module WikiHelper
  
  def boundaries_map
    map({:width => "525", :height => "500",
      :center => "-122.01686382293701, 37.31932181336203",
      :zoom => "3",
      :boundary_line => true,
      :marker => "-122.02016830444336, 37.31850270698815",
      :text => "Tri-Cities Little League",
      :url => "http://www.tricitiesbaseball.org"}
    )
  end
  
  def breadcrumb(*items)
    items.flatten!
    html = "<div id='breadcrumb'>"
    items.each do |item| 
      split_item = item.split('|')
      html << wiki_link(split_item[0],split_item[1])
      html << " &gt; "
    end
    html << "#{@page.name.titleize}\n"
    html << "</div>\n"
    html  
  end
  
  def email(email_address)
    name = email_address
    html_options = {:encode => 'javascript'}
    
    # If sending a page as an email 'mail_to' won't be defined so set it up manually
    if respond_to?('mail_to')
      mail_to(email_address, name, html_options)
    else
      "<a href=mailto:#{email_address}>#{email_address}</a>"
    end
  end
  
  # Event helpers, keep together under "Event"  
  def game_schedule(options = {})
    render_events(options.merge(:kind => Event::GAME))
  end
  
  def practice_schedule(options = {})
    render_events(options.merge(:kind => Event::PRACTICE))
  end
  
  def game_and_practice_schedule(options = {})
    render_events(options.merge(:kind => [Event::GAME, Event::PRACTICE]))
  end
  
  def event_schedule(options = {})
    render_events(options.merge(:kind => Event::EVENT))
  end
  
  def schedule(options = {})
    render_events(options)
  end
  # End of "Event" helpers
  
  def left_menu_with_markers(markers, *items)
    items.flatten!
    marker_num = 0
    marker = nil
    html = "<ul class='left_menu'>\n"
    items.each_with_index do |item, index| 
      split_item = items[index].split('|')
      if index == 0
        html << "  <li class='submenu'>"
      else
        html << "  <li>"
      end
      if markers.size > 0
        marker = markers[marker_num]
        marker_num = marker_num.succ.modulo(markers.size)
      end
      html << tag_href_selected(split_item[0],split_item[1],split_item[2], marker)
      html << "</li>\n"
      
    end
    html << "</ul>\n"
    html
  end
  
  def left_menu(*items)  
    left_menu_with_markers([], *items)
  end
  
  def left_menu_auto(parent, sort_method = 'created_at')
    parent_page = @wiki.read_page_by_link(parent)
    if sort_method == 'name'
      pages = parent_page.children.sort_by {|page| page.name.downcase} rescue []
    else
      pages = parent_page.children.sort_by {|page| page.created_at}.reverse rescue []
    end
     
    pages.unshift(parent_page)
    authorized_pages!(pages)    

    names = pages.collect {|page| "#{page.name}|#{page.link}"}
    names = ['(No items)'] if names.empty?

    left_menu(names)
  end
  
  def blog(page_link = @page.link, options = {})  
    render_component(:controller => 'blog', :action => 'show',
      :params => params_merge_with_no_layout(options).merge({:page => @page.page_number, :parent => page_link}))
  end
  
  def locations_menu
    # Find unique locations
    locations = Lookup.find_all(Lookup::LOCATION)
    last_page = ''
    locations.map! do |location|
      if last_page == location.page_name
        nil
      else
        last_page = location.page_name
        location
      end
    end
    locations.compact!
    
    html = "<div id='breadcrumb'>#{wiki_link('HomePage', 'Home')} &gt; #{wiki_link('Locations')} &gt; #{@page.name}</div>\n"
    html << "<hr>\n"
    html << "<ul class='left_menu'>\n"
    html << "<li class='title'>Locations...</li>\n"
    for location in locations
      unless location.page_name.nil? or location.page_name.empty?
        html << tag_li_href_selected(location.page_name) + "\n"
      end  
    end  
    html << "</ul>\n"
    html
  end
  
  def login_block
    <<-EOF
      <div class="role_none" style="display:none">
        #{link_to('Login', {:controller => 'user', :action => 'login'})}
      </div>
      <div class="role_#{ROLE_USER}" style="display:none">
        #{link_to('Logout', {:controller => 'user', :action =>   'logout'})}
      </div>
    EOF
  end
  
  def map(options = {})
    gmap_defaults = {:width => "525", :height => "500",
      :center => "-122.01686382293701, 37.31932181336203",
      :zoom => "2",
      :boundary_line => false,
      :key => @wiki.config[:google_key]
    }  
    @gmap = gmap_defaults.merge(options)
    @gmap[:marker] = @gmap[:center] if @gmap[:marker].nil?
    
    # Convert from single marker syntax to multiple markers syntax
    marker_hash = {}
    marker_hash[:point] = @gmap[:marker] if @gmap[:marker]
    marker_hash[:text] = @gmap[:text] if @gmap[:text]
    marker_hash[:url] = @gmap[:url] if @gmap[:url]
    markers = {:markers => [marker_hash]}
    @gmap = markers.merge(@gmap)
    
    render(:partial => "layouts/google_map", :no_layout => true)
  end
  
  def no_cache
    '<!-- no_cache -->'
  end
  
  # Use an Ajax callback here because the roster will include last names and phones if the logged in person
  # has an Editor role or greater.
  # We could simply use no_cache and regenerate the page for each call, but this method allows us to cache the main 
  # page and just generate the part that changes depending on the users role.  
  def roster(options)
    javascript_tag(remote_function(:update => 'roster', 
    :url => {:controller => 'register', :action => 'roster', :no_layout => true}.merge(options))) + "\n" +
    "<div id='roster'>&nbsp;</div>"
    
    # This is the old way
    #render_component :controller => 'register', :action => 'roster', 
    #:params => params_merge_with_no_layout(options)
  end
  
  def user_first_name
    @user.firstname rescue ''
  end
  
  def user_last_name
    @user.lastname rescue ''
  end
  
  def user_full_name
    @user.full_name rescue ''
  end
  
  def user_list
    html = "<ul>\n"
    User.find(:all, :conditions => ['paid = ?', true], :order => 'lastname').each do |user|
      link = @wiki.make_link(user.full_name)
      html << "<li>#{link}</li>\n"
    end
    html << "</ul>\n"
    html
  end
  
  def user_paid?
    @user.paid
  end  
  
  def user_wait_list?
    @user.wait_list?
  end   
  
  def google_ads(ad_type = 2)
    width = 120
    height = 90
    format = "120x90_0ads_al_s"
    if ad_type == 2
      width = 120
      height = 600
      format = "120x600_as"
    end
    
    html = "<script type=\"text/javascript\"><!--\n"
    html << "  google_ad_client = \"#{@wiki.config[:google_ad_client]}\";\n"
    html << "  google_ad_width = #{width};\n"
    html << "  google_ad_height = #{height};\n"
    html << "  google_ad_format = \"#{format}\";\n"
    html << "  google_ad_type = \"text_image\";\n"
    html << "  google_ad_channel =\"\";\n"
    html << "//--></script>\n"
    html << "<script type=\"text/javascript\"\n"
    html << "  src=\"http://pagead2.googlesyndication.com/pagead/show_ads.js\">\n"
    html << "</script>"
    html
  end
  
  def signup(options = {})
    render_component :controller => 'user', :action => 'signup', 
    :params => params_merge_with_no_layout(options)
  end
  
  def style_additions(styles)
    @style_additions = '' if @style_additions.nil?
    @style_additions << styles
  end
  
  def full_page
    @middle_column_size = 'full'
    @left_column_show = FALSE
    @right_column_show = FALSE
  end
  
  def edit_page_link(page)
    page_kind_name = 'Page'
    if page.kind == Page::POST
      page_kind_name = 'Post'
    end
    
    link_to(image_tag('edit.gif') + " Edit #{page_kind_name}", 
    {:controller => 'wiki', :action => 'edit', :link => page.link}, 
    {:class => 'edit_link', :name => "Edit #{page.name}", :title => "Edit #{page.name}"})
  end
  
  def add_page_link(page)
    parent_link = nil
    page_kind = nil
    page_kind_name = 'Page'
    if page.kind == Page::BLOG
      parent_link = page.link
      page_kind = Page::POST
      page_kind_name = 'Post'
    elsif page.kind == Page::POST
      parent_link = page.parent.link rescue nil
    page_kind = Page::POST
      page_kind_name = 'Post'
    end
    
    link_to(image_tag('plus.gif') + " Add #{page_kind_name}", 
    {:controller => 'wiki', :action => 'new', :parent_link => parent_link, :kind => page_kind}, 
    {:class => 'edit_link', :name => "Add Page", :title => "Add Page"})
  end
  
  def energy_usage(options = {})
    render_component(:controller => 'usage', :action => 'show', 
      :params => params_merge_with_no_layout(options).merge({:page_link => @page.link}))
  end
  
  def is_page?(name)
    @page.name == name rescue false
  end
  
  #-------------
  private
  
  def params_merge_with_no_layout(options) 
    no_layout = {:no_layout => true}
    if params.nil?
      p = options
    else 
      p = params.merge(options)
    end
    
    if p.nil?
      p = no_layout
    else
      p = p.merge(no_layout) 
    end
    p 
  end
  
  def render_events(options)
    render_component :controller => 'events', :action => 'list', 
    :params => params_merge_with_no_layout(options)
  end

  
  def plugins( page_name )
    [ { :value => 'none',
      :label => 'None',
      :url => { :controller => 'webdav', :action => 'clear' } },
    { :value => 'file_upload',
      :label => 'File Upload',
      :url => { :controller => "attachment", :action => 'show',
        :params => {:page_name => page_name }} },
    { :value => 'xythos_browse',
      :label => 'Xythos - Browse',
      :url => { :controller => 'webdav', :action => 'show_bar' } },
    { :value => 'xythos_upload',
      :label => 'Xythos - Upload',
      :url => { :controller => 'webdav', :action => 'show_upload' } },
    { :value => 'youtube',
      :label => 'YouTube',
      :url => { :controller => "drag_and_drop_media", 
        :action => 'youtube',
        :params=> {:key=>@wiki.config[:youtube_key] } } },   
    { :value => 'flickr',
      :label => 'Flickr',
      :url => { :controller => "drag_and_drop_media", 
        :action => 'flickr',
        :params => {:key => @wiki.config[:flickr_key] } } }, 
    { :value => 'davetv',
      :label => 'DaveTV',
      :url => { :controller => "drag_and_drop_media", 
        :action => 'davetv' } },  
    { :value => 'amazon',
      :label => 'Amazon',
      :url => { :controller => "drag_and_drop_media", 
        :action => 'amazon',
        :params => {:key => @wiki.config[:amazon_key]}} },                                             
    ]    
  end
  
end
