require 'rexml/document'
require 'drag_and_drop_media_model'

class DragAndDropFlickr < DragAndDropMediaModel
    
	def initialize( name, api_key = nil, per_page = 8, 
	                default_tag = 'okapi', default_width = 180 )
    @width = default_width
    super( name, per_page, default_tag )
		@api_key = api_key
		@api_path=xmlrpc_client('api.flickr.com','/services/xmlrpc',80)
	end
	
	def search_implementation(tags,user,page,per_page)
	  begin
	    args = { 'per_page' => per_page,
                 'page' => page,
                 'api_key' => @api_key  }
        if tags && tags.size > 0
	      args['tags'] = @tags 
	    end
	    if user && user.size > 0
          if (user_id = people_findByUsername(user))
            args['user_id'] = user_id 
          end
	    end
	    photos = xmlrpc_get_xml('flickr.photos.search',args,'//photo')
      items = []
      furl = 'http://www.flickr.com/photos'
      statfurl = 'http://static.flickr.com'
      for photo in photos
        p = {}
        p[:title] = photo.attributes["title"]
        owner_id = photo.attributes["owner"]
        if user && user.size > 0
          p[:creator] = user
        else
          p[:creator] = owner_id
        end
        pid = photo.attributes["id"]
        secret = photo.attributes["secret"]
        server = photo.attributes["server"]
        p[:thumb] = statfurl + '/' + "#{server}/#{pid}_#{secret}_s.jpg"
        p[:thumb_width] = 75
        p[:thumb_height] = 75
	        m_img = statfurl + '/' + "#{server}/#{pid}_#{secret}_m.jpg"
        url =  "#{furl}/#{owner_id}/#{pid}"	        
        p[:html] = html_code(url,p[:title],m_img)
        items << p
      end
      return items
    rescue Exception
      return nil
	  end
  end
		   
  private
  
    # creates an html embeddable image tag
    def html_code(url, title, source) 
      str = '<a href="' + url + '" target="_blank"><image alt="' +
             title + '" ' + 'width="' + @width.to_s + '" ' +
             'src="' + source + '" /></a>'
    end  
    
	# this returns flickr user id based on flickr username
	def people_findByUsername( username )
	  if username 
	    args = {'username' => username, 'api_key' => @api_key }
        users = xmlrpc_get_xml('flickr.people.findByUsername',args,'/user')
        if users && users[0]
          return users[0].attributes["id"]
        end
	  else
        return nil
      end
	end
	
end


