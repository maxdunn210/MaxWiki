require 'rexml/document'
require 'drag_and_drop_media_model'

class DragAndDropItunes < DragAndDropMediaModel

  # of course tags=title search terms, and user=author
    
	def initialize( name, per_page = 8, default_tag = 'pink_floyd', 
	                index = 'song', default_width = 180 )
    @width = default_width
    super( name, per_page, default_tag )
    @api_index = index
    @on = false	    
		@api_path='http://www.apple.com/itunes/scripts/itmsSearch.php?'
	end
	
	def search_implementation(tags,user,page,per_page)
    # user and per_page are ignored
    if (user !=nil && user.size>0) 
      return nil
    end
	  tags.gsub!(/\s/,'+')
	  options = { 'searchTerm' => tags,
                  'SearchType' => @api_index }             
      itunes = uri_get_response( options )
      itunes = itunes.scan(/\{.*?\}/)
      items = []
      itunes.each do |it|
        h = {}
        it.gsub!(/\{|\}/,'')
        attr = it.split(',')
        attr.each do |a|
          i = a.index(':')
          if i 
            key = a[0..(i-1)]
            key = key.gsub(/"/,'').strip
            value = a[i+1..(a.size-1)]
            value = value.gsub(/"/,'').strip
            h[key] = value
          end
        end
        itm = {}
        if h['artworkUrl60']
          itm[:thumb] = h['artworkUrl60']
        else
          itm[:thumb] = 'music.jpg'
        end
        itm[:thumb_width] = 60
        itm[:thumb_height] = 60
        if h['artworkUrl100']
          img = h['artworkUrl100']
        else
          img = itm['thumb']
        end        
        if h['artistName']
          itm[:creator] = h['artistName']
        else
          itm[:creator] = 'unspecified'
        end
        if h['itemName']
          itm[:title] = h['itemName']
        else
          itm[:title] = 'unspecified'
        end    

        if h['artistLinkUrl'] && h['artistLinkUrl'] != 'null'
          itm[:html] = html_code(h['artistLinkUrl'], itm[:title], 
                                   itm[:creator], img) 
        else
          itm[:html] = html_code('http://www.itunes.com', itm[:title], 
                                   itm[:creator], img) 
        end     
    
        items << itm
	  end  
	  return items
	end	
private
  def html_code(url, title, creator, img) 
      str = '<a href="' + url + '" target="_blank"><image alt="' +
             title + '" width="' + @width.to_s + '" ' +
             'src="' + img + '" /></a><br>' +
             '<b>' + title + '</b><br> <i>by</i> ' + creator              
  end	 
end

