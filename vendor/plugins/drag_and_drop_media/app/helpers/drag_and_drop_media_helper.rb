module DragAndDropMediaHelper
   
  # this creates a rhtml tag that can be dragged
  def media_draggable_icon(moo,photo)
    begin
      rid = photo.object_id.to_s 
      str = image_tag( photo[:thumb],  
                       :alt => photo[:title] +' by '+photo[:creator], 
                       :title => photo[:title] +' by '+photo[:creator],
                       :width => photo[:thumb_width].to_i*0.66,
                       :height => photo[:thumb_height].to_i*0.66,
                       :onmouseover => 
                            'drag_and_drop_media_thumbnail_blowup(\'' + rid + '\',1.5)',
                       :ondblclick => "drag_and_drop_media_dblclick(" + rid + ")",
                       :id => rid,
                       :class => 'drag_and_drop_media_thumbnail' ) +
            draggable_element( rid, :revert => true )
    rescue
      "empty"
    end
  end
 
  def media_draggable_text(moo,photo)
    begin
      rid = photo.object_id.to_s 
      str = '<div id="' + rid +'" class="drag_and_drop_media_description">' + 
            '<b>' + photo[:title] + '</b><br> <i>by</i> ' +
            photo[:creator] + '</div>' +
            draggable_element( rid, :revert => true)
    rescue
      "empty"
    end
  end  
  
  def drag_map_javascript(drag_map)
    html = "\n<script type=\"text/javascript\">\n"
    html << "//<![CDATA[\n"
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
   
end






