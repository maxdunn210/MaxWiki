module WebdavHelper
  
  def webdav_bar
    render_component :controller => 'webdav', :action => 'update_bar'
  end
  
  def webdav_browser(server, username = nil, password = nil)
    render_component :controller => 'webdav', :action => 'list', 
    :params => {:webdav_server => server, :webdav_username => username, :webdav_password => password, 
      :webdav_dir => params[:webdav_dir], :connection => 'browser'}
  end
  
  def webdav_search(server, username = nil, password = nil, conditions = nil, properties = nil)
    render_component :controller => 'webdav', :action => 'search', 
    :params => {:webdav_server => server, :webdav_username => username, :webdav_password => password, 
      :webdav_dir => params[:webdav_dir], :connection => 'search',
      :conditions => conditions, :properties => properties}
  end
  
  def webdav_link(element, connection, drag = false, list_height = 0, show_checkout = false)  
    html = link_to(image_tag(icon(element.name, element.directory?)), element.href)
    html << "\n"
    if element.directory?
      path = Webdav.parse_path(element.href)
      
      # show_checkout is used when browsing
      if show_checkout
        html << link_to(element.name, :webdav_dir => path, :connection => connection,
                        :drag => drag, :list_height => list_height, :show_checkout => show_checkout)
      else
        html << link_to_remote(element.name, 
                               :update => "webdav_browser",
        :url => { :controller => "webdav", :action => "update_browser", 
          :webdav_dir => path, :connection => connection,
          :drag => drag, :list_height => list_height, :show_checkout => show_checkout},
        :loading => "Element.show('indicator')",
        :complete => "Element.hide('indicator')"  )
      end
    else
      if drag
        html << %Q{<span class="move" id="#{element.object_id.to_s}" }
        html << %Q{ondblclick="addDropped2Fck( 'content', #{element.object_id.to_s})"}
        html << ">"
        html << "#{element.name}"
        html << "</span>"
        html << draggable_element(element.object_id.to_s, :revert => true)
      else
        html << link_to(element.name, element.href)
      end   
    end  
    html << "\n"
    html
  end
  
  def webdav_edit_link(element)
    return '&nbsp;' if element.directory?
    
    options = {:controller => 'webdav',  :connection_id => @connection_id, :path => Webdav.parse_path(element.href)}
    
    if element.locked? || element.checked_out?
      if element.locked_by_me?
        link_to(image_tag('lock_green.gif', :float => 'none', :title => "Locked by me (#{element.locked_by})"), options.merge(:action => 'checkin'))
      else
        link_to(image_tag('lock_red.gif', :float => 'none', :title => "Locked by #{element.locked_by}"), options.merge(:action => 'locked'))
      end
    else
      link_to(image_tag('lock.gif', :float => 'none'), options.merge(:action => 'checkout'))
    end
  end      			
  
  def webdav_last_list_url
    session[:last_webdav_list_url]
  end
  
  def icon(name, directory)
    if directory
      return 'icon_folder.gif'
    end
    
    last_ext = File.suffix(name).downcase
    ext = last_ext
    if last_ext == 'zip'
      next_to_last_ext = File.suffix(File.basename(name, '.*')).downcase
      ext = next_to_last_ext unless next_to_last_ext.blank?
    end
    case ext
    when 'gif', 'jpg', 'png', 'bmp': 'icon_file_image.gif'
    when 'doc': 'icon_file_msword.gif'
    when 'xls': 'icon_file_excel.gif'
    when 'pdf': 'icon_file_pdf.gif'
    when 'htm', 'html': 'icon_file_html.gif'
    when 'ppt': 'icon_file_ppt.gif'
    when 'txt', 'text', 'log': 'icon_file_text.gif'
    when 'exe', 'bat', 'rb': 'icon_file_application.gif'
    when 'key': 'icon_file_key.gif'
    when 'zip': 'icon_file_zip.gif'
    when 'mp3': 'icon_file_audio.gif'
    when 'mp4', 'avi': 'icon_file_video.gif'
    else 
      if last_ext == 'zip'
        'icon_file_zip.gif'
      else
        'icon_file_unknown.gif'
      end
    end
  end
  
  def include_doc(href, username = nil, password = nil, conversion_type=nil)
    
    # Trigger autoload of the plugin if present
    present = MaxwikiInclude rescue nil
    if present
      MaxwikiInclude.html(href, username, password, conversion_type, MY_CONFIG[:jooconverter])
    else
      "<p>Can't include document. MaxWiki Convert plug-in not installed.</p>"
    end
  end  
  alias :webdav_include :include_doc
  
  def webdav_link_insert(file_url)
    return '' if file_url.nil? or file_url.empty?
    
    html = "\n<script type=\"text/javascript\">\n"
    html << "insertAtCursor(document.editForm.content, '#{file_url}')\n"
    html << "</script>\n"
    html
  end
  
  def webdav_get_connection(connection_type)
    connection_id = session["webdav_#{connection_type}_connection_id".to_sym]
    connection = session[:webdav_connections][connection_id] rescue {}
    connection = {} if connection.nil?  
    connection
  end
  
end