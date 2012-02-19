require 'rexml/document'
require 'drag_and_drop_media_model'

class DragAndDropYoutube < DragAndDropMediaModel
    
	def initialize( name, dev_id = nil, per_page = 8, 
	                default_tag = 'okapi', default_width = 180 )
	    super( name, per_page, default_tag )
	    @width = default_width
		@api_key = dev_id
		@api_path=xmlrpc_client('www.youtube.com','/api2_xmlrpc',80)	
	end
	
	def search_implementation(tags,user,page,per_page)
	  if tags && tags.size > 0 && user && user.size > 0
	    search_by_tags_and_user(tags,user)
	  elsif tags && tags.size > 0
	    search_by_tags(tags,page,per_page)
	  elsif user && user.size > 0
	    search_by_tags_and_user(nil,user)
	  else
	    return nil
	  end
	end
	
private
	
	# when searching by tag, you can specify page/per_page
  def search_by_tags(tags,page,per_page)
    begin
	    args = { 'dev_id'=>@api_key, 
	             'tag' => tags,
	             'per_page' => per_page,
                 'page' => page }
        videos = xmlrpc_get_xml('youtube.videos.list_by_tag',args,'//video')         
        rvideos = []
        for video in videos
          html = html_code(video.elements["id"].text,
                           video.elements["thumbnail_url"].text )        
          v = { :title => video.elements["title"].text,
                :thumb => video.elements["thumbnail_url"].text,
                :thumb_width => 80,
                :thumb_height => 60,
                :creator => video.elements["author"].text,
	              :html => html }	            
	      rvideos << v
	    end
	    return rvideos
 	  rescue Exception
      return nil
	  end 	 	  
	end
	def search_by_tags_and_user(tags,user)
    begin
	    args = { 'dev_id'=>@api_key, 
	             'user' => user }  
	    videos = xmlrpc_get_xml('youtube.videos.list_by_user',args,'//video') 
	    items = []
        for video in videos
          vid = video.elements["id"].text
          html = html_code(video.elements["id"].text,
                           video.elements["thumbnail_url"].text )
          v = { :title => video.elements["title"].text,
                :thumb => video.elements["thumbnail_url"].text,
                :thumb_width => 99,
                :thumb_height => 75,
                :creator => video.elements["author"].text,                
	              :html => html }
	      video_tags = video.elements["tags"].text
          if !tags || video_tags.include?( tags )
	        items << v
	      end
	    end	    
	    return items
 	  rescue Exception
      return nil
	  end
	end

  def html_code(vid,thumb)            
    heigth = @width * 5 / 6
    url = '"http://www.youtube.com/v/' + vid + ' "'
    str = '<object alt="' + thumb + '"> <param name="movie" value=' +
          url + '></param> <embed src=' + url + 
          ' type="application/x-shockwave-flash" ' + 
          ' width="' + @width.to_s + '" height="' +
                 heigth.to_s + '" ' +
          '></embed></object>' 
  end		 
		
=begin		
	def get_profile(user)
	  args = { 'dev_id'=>@dev_id, 'user' => user }
      str = @client.call('youtube.users.get_profile',args)
      p args
      p str
      res = REXML::Document.new(str)
	  return res.elements["//first_name"].text, res.elements["//last_name"].text
	end
=end
			   
end


