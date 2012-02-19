require 'rexml/document'
require 'drag_and_drop_media_model'

class DragAndDropDavetv < DragAndDropMediaModel
    
	def initialize( name, per_page = 8, default_tag = 'cool', 
	                default_width = 180 )
    @width = default_width
    super( name, per_page, default_tag )
		@api_path='http://dave.tv/DaveApiRest.aspx?'
	end
	
	def search_implementation(tags,user,page,per_page)
	  options = [ [ 'method', 'ContentItemPackageSearch'],
	              [ 'Auth.UserName', 'anonymous'],
                  [ 'options', 'ThumbnailUri'],
                  [ 'tagName', tags ] ]           
    videos = uri_get_xml( options, '//ContentItemFlat')
    items = []
	  for video in videos
        v = {}
	    vid = video.elements["ContentItemID"].text
        user_id = video.elements["UserID"].text 
        v[:html] = html_code(vid)
	    if video.elements["ThumbnailUri"]
	      v[:thumb] = video.elements["ThumbnailUri"].text 
	      v[:thumb_width] = 80
	      v[:thumb_height] = 60
	      v[:creator] = video.elements["UserID"].text 
        attributes = video.elements.to_a("Attributes/ContentItemAttribute")
	      attributes.each do |attr|
	        if attr.elements['Name'].text = 'Title'
	          v[:title] = attr.elements['Val'].text
	          break;
	        end
	      end
          if !(user && user.size > 0) || user_id == user
	        items << v	      
	      end	      
	    end
	  end                 
	  return items
	end
private
  def html_code(vid)
    height = (@width.to_f * 0.87).to_i
    str = '<embed FlashVars="channelContentId=' + vid.to_s  +
          '" allowScriptAccess="never" ' +
          'src="http://www.dave.tv/DBOX/dbox_small.swf" ' +
          'type="application/x-shockwave-flash" ' + 
          'width="' + @width.to_s + '" height="' + height.to_s + 
          '"></embed>'  
    return str     
  end	
end
