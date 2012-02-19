require "webdav"
require 'digest/sha1'

# This is needed to prevent a weird error with edge Rails 5005 on Mongrel
# "A copy of ApplicationController has been removed from the module tree but is still active!"
require 'application'

class WebdavController < ApplicationController
  
  include WebdavHelper
  upload_status_for  :upload
  layout "main", :only => [:locked, :checkin, :checkout]
  
  def list
    save_url(:last_webdav_list_url)
    update_connection_info
    @webdav = webdav_new
    @webdav.dir_list(params[:webdav_dir]) unless @webdav.error?
    create_drag_map(@username, @password) unless @webdav.error?
  end
  
  def search
    save_url(:last_webdav_search_url)
    update_connection_info
    # Parse these rather than using eval. Safer and easier for the user to write
    conditions = eval("[#{params[:conditions]}]") rescue nil
    conditions.map! {|c| [c[0].to_sym, c[1].to_sym, c[2]]}
    properties = eval("[#{params[:properties]}]") rescue nil
    @webdav = webdav_new
    @webdav.search_list(params[:webdav_dir], conditions, properties) unless @webdav.error?
    create_drag_map(@username, @password) unless @webdav.error?
  end
  
  def browser_connection_info
    update_connection_info
    update_browser
  end
  
  def show_bar
    update_bar
  end
  
  def show_upload
    update_upload
  end
  
  def update_browser
    # This can come from a browser or a bar, so needs to have params[:connection] passed in
    list
    render :partial => 'webdav_browser', :no_layout => true, 
    :locals => {:connection => params[:connection], :drag => (params[:drag] == 'true'), 
      :list_height => params[:list_height].to_i, :show_checkout => params[:show_checkout]}
  end
  
  def update_bar
    params[:connection] = 'bar'
    list
    render :partial => 'webdav_bar', :no_layout => true
  end
  
  def update_upload
    params[:connection] = 'upload'
    render :partial => 'webdav_upload', :no_layout => true, :locals => {:connection => 'upload', :no_insert => false}
  end
  
  def clear
    render :inline => '&nbsp;'
  end
  
  def upload
    update_connection_info
    
    begin    
      if params[:upload].nil? or params[:upload][:file].class == String
        @upload_error = "No file selected"
      else
        @webdav = webdav_new
        unless @webdav.error?
          file = params[:upload][:file]
          name = File.basename(file.original_filename)
          @file_path = URI.escape([@path, name].join('/'))
          
          token = @webdav.get_lock_token(@file_path)
          if !@webdav.error? || @webdav.error_msg.include?("not locked")
            data = file.read #TODO This should use an IOStream to better handle large files
            @webdav.put(@file_path, data, token)
          end
        end  
        @upload_error = @webdav.error_msg if @webdav.error?
      end  
    rescue => e
      @upload_error = "#{e}"
    end
    
    if @upload_error.nil?
      @message = "#{name} uploaded."
      if params[:no_insert]
        finish_upload_status "'#{@message}'"
      else
        link = "\\n\"#{name}\":#{@server}#{@file_path}\\n"
        finish_upload_status "insertAndReturnString(parent.document.editForm.content, '#{link}', '#{@message}')"
      end
    else
      finish_upload_status "'#{@upload_error}'"
    end    
  end  
  
  def locked
    do_lock_unlock(:query_lock)
  end
  
  def checkout
    do_lock_unlock(:lock)
  end
  
  def checkin
    do_lock_unlock(:query_unlock)
    connection = webdav_get_connection('browser')
    dir = File.dirname(Webdav.parse_path(params[:path]))
    connection_id = save_connection_info("#{connection[:server]}#{dir}", connection[:username], connection[:password])
    session[:webdav_checkin_connection_id] = connection_id
  end
  
  def unlock
    do_lock_unlock(:unlock)
    if @webdav.error?
      redirect_to :action => checkin
    else
      redirect_to_url webdav_last_list_url
    end
  end
  
  #--------------------------
  private  
  
  def do_lock_unlock(which)
    @webdav = webdav_new(params[:connection_id])
    
    @file_path = URI.unescape(params[:path]) rescue ''
    @file_name = File.basename(@file_path)
    @file_url = @server + @file_path
    
    if which == :unlock
      token = @webdav.get_lock_token(@file_path)
      @webdav.unlock(@file_path, token) unless @webdav.error?
    elsif which == :lock
      @webdav.lock(@file_path) unless @webdav.error?
    elsif which == :query_lock
      attributes = @webdav.lock_query(@file_path) unless @webdav.error?
      @webdav.item = WebdavItem.new(@file_name, @file_url, attributes)
    end
    
    if @webdav.error?
      flash[:error] = @webdav.error_msg
    end
  end
  
  # If server information specified save and use that information, otherwise, use saved connection
  def update_connection_info
    if !params[:webdav_server].blank?
      @connection_id = save_connection_info(params[:webdav_server], params[:webdav_username], params[:webdav_password])
      session["webdav_#{params[:connection]}_connection_id".to_sym] = @connection_id unless params[:connection].blank?
    elsif !params[:connection].blank?
      @connection_id = session["webdav_#{params[:connection]}_connection_id".to_sym]
    end
  end  
  
  def save_connection_info(href, username, password)
    server = Webdav.parse_server(href)
    path = Webdav.parse_path(href)
    connection_id = Digest::SHA1.hexdigest("#{server}#{username}")[0..19]
    session[:webdav_connections] = {} if session[:webdav_connections].nil?
    session[:webdav_connections][connection_id] = {:server => server, :path => path, :username => username, :password => password}
    connection_id
  end
  
  def webdav_new(connection_id = @connection_id)
    info = session[:webdav_connections][connection_id] rescue {}
    info = {} if info.nil?
    
    @connection_id = connection_id
    @server = info[:server]
    @path = info[:path]
    @username = info[:username]
    @password = info[:password]
    Webdav.new("#{@server}#{@path}", @username, @password, @user.login)
  end
  
  def create_drag_map(username = '', password = '')
    @drag_map = {}
    return unless @webdav.list
    
    password = '' if password.nil?
    authstr = ''
    authstr << ", '#{username}', '#{password}'" unless username.nil? || username.empty?
    
    @webdav.list.each do |element| 
      unless element.directory?
        #TODO Use mime_types for this
        if ['gif', 'jpg', 'png', 'bmp'].include?(File.suffix(element.href))
          str = "<img src='#{element.href}' alt='#{File.basename(element.href).capitalize}' />"
        else
          str = "\n<div class='include_marker'>\n"
          str << "((Include #{element.href}))"
          str << "\<\%= include_doc('#{element.href}'#{authstr}) \%\>\n"
          str << "</div>\n"
        end
        @drag_map[element.object_id.to_s.dump] = str.dump
      end  
    end  
  end  
  
end
