# need these because these object are marshalled into the session object...
require 'drag_and_drop_flickr'
require 'drag_and_drop_youtube'
require 'drag_and_drop_davetv'
require 'drag_and_drop_amazon'
require 'drag_and_drop_itunes'

class DragAndDropMediaController < ApplicationController	
  
  def flickr
    obj = session[:Flickr] ||= 
            DragAndDropFlickr.new( :Flickr, params[:key], 8, 'music', 200 )
    get_media_and_render_container( obj )
  end   
  def youtube
    obj = session[:YouTube] ||= 
            DragAndDropYoutube.new( :YouTube, params[:key], 8, 'music', 200 )
    get_media_and_render_container( obj )
  end    
  def davetv
    obj = session[:DaveTV] ||= 
            DragAndDropDavetv.new( :DaveTV, 8, 'cool', 200  )
    get_media_and_render_container( obj )
  end 
  def amazon
    obj = session[:Amazon] ||= 
            DragAndDropAmazon.new( :Amazon, params[:key], 'Geoffrey Moore','Books', 200 )
    get_media_and_render_container( obj )
  end 
  def itunes
    obj = session[:Itunes] ||= DragAndDropItunes.new( :Itunes, 8, 'Pink Floyd','song', 200 )
    get_media_and_render_container( obj )
  end        

  def scroll_right
    if params[:media] && (obj=session[params[:media].to_sym])
      obj.forward 
      get_media_and_render(obj)
    else
      render :nothing => true
    end
  end
  def scroll_left
    if params[:media] && (obj=session[params[:media].to_sym])
      obj.backward 
      get_media_and_render(obj)
    else
      render :nothing => true
    end
  end
  def toggle_display
    if params[:media] && (obj=session[params[:media].to_sym])
      obj.toggle       
      get_media_and_render(obj) 
    else
      render :nothing => true
    end
  end
  def update_display
    if params[:media] && (obj=session[params[:media].to_sym])
      obj.update(params[:tags],params[:user])
      get_media_and_render(obj)                                
    else
      render :nothing => true
    end
  end

  def drop
    if ( params[:id] =~ /\A&service/ )
      @title = CGI.unescape( params[:id].split('title=')[1].split('&')[0] ) 
      @html = CGI.unescape( params[:id].split('html=')[1].split('&')[0] )        
    else
      @title = "--"
      @html = params[:id]
    end
    render :partial => 'drop'
  end

private

  def get_media_and_render_container( obj )
    obj.visible! if params[:start_visible] == 'yes' || !params[:hideable]
    get_media( obj )
    @hideable = params[:hideable]
    render :partial => 'container'
  end
  def get_media_and_render( obj )
    get_media( obj )
    @hideable = params[:hideable]
    render :partial => 'selection', :no_layout => true
  end
  
  def get_media( obj )
    time = Time.now.seconds_since_midnight 
    begin
      @items = obj.search if obj && obj.on
    rescue => e
      logger.error("DragAndDropMediaController.get_media error: #{e}")
      @items = nil
    end   
    
    if @items 
      @drag_map = {} 
      @items.each do |item| 
        str = html_info(obj.display_name.to_s,item)      
        #str = rest_info(obj.display_name.to_s,item)  
        @drag_map[item.object_id.to_s.dump] = str.dump
      end
    end      
    @visible = obj.on
    @tags = obj.tags
    @user = obj.user
    @page = obj.page
    @per_page = obj.per_page
    @media = obj.display_name.to_s
    @search_time = (Time.now.seconds_since_midnight - time)
  end
  
  def html_info(service,photo)
    str = photo[:html]
  end
  
  def rest_info(service,photo)
    str = '&service=' + service + '&' + 
          'title=' + CGI.escape(photo[:title] +' by '+ photo[:creator]) + '&' +
          'html=' + CGI.escape(photo[:html]) + '&' +
          'thumb=' + CGI.escape(photo[:thumb]) + '&' +
          'twidth=' + CGI.escape(photo[:thumb_width].to_s) + '&' +
          'theight=' + CGI.escape(photo[:thumb_height].to_s) 
    return str
  end   
  
end


