module GoogleMapHelper

#
#  This helper is pretty generic - can be used in other Rails apps also, does
#  not require other views or controllers.
#  
#  It requires some javascript, a version of which is appended at the bottom as
#  a comment.
#
#  The following section can be embedded in a wikipage to serve as documentation.
#
=begin
<h3>Embedding Google maps</h3>

Embedding Google maps is simple. 

<br />
<h3>Default</h3>

All parameters have defaults, so the simplest call is:
<pre><code>
<%= gmap  %>
</code></pre>
<%= gmap %>

<br />
<h3>By longitude and latitude</h3>
Use longitude and latitude to define your location:
<pre><code>
<%= gmap :lat => 37.32, :long => -122.02 %>
</code></pre>

<br />
<h3>By Address</h3>
Use an address (similar to what you enter on maps.google.com):
<pre><code>
<%= gmap :address => "100 Main Street, CA 95030" %>
</code></pre>
<%= gmap :address => "100 Main Street, CA 95030" %>

<br />
<h3>Define Size of Map on Page</h3>
Define the size of the map on your wiki page, in pixels:
<pre><code>
<%= gmap :address => "100 Main Street, CA 95030",
         :width => "500", :height => "300" %>
</code></pre>

<br />
<h3>Zoom the map</h3>
The default zoom is 15 (street level).
<pre><code>
<%= gmap :marker => false, 
       :lat => 37.32, :long => -122.02, :zoom => 11   %>
</code></pre>
<%= gmap :marker => false, 
       :lat => 37.32, :long => -122.02, :zoom => 11   %>

<br />
<h3>Markers</h3>
By default, the map has a marker at the specified lat/long or address. The marker can be turned off by setting :marker => false - see previous example.

In addition, other markers can be added to maps. In this case, the map has to be named using the :gmapid parameter. After that, multiple markers can be added by referring to the same :gmapid.

If :content is defined, a click on the marker will open a window with the content.

<pre><code>
<%= gmap :gmapid => 'mymap', 
       :lat => 37.32, :long => -122.02 %>
<%= gmarker :gmapid => 'mymap', 
       :lat => 37.32, :long => -122.023,
       :content => "Hi" %>
</code></pre>
<%= gmap :gmapid => 'mymap', 
       :lat => 37.32, :long => -122.02 %>
<%= gmarker :gmapid => 'mymap', 
       :lat => 37.32, :long => -122.023,
       :content => "Hi" %>


<br />
<h3>Boundaries</h3>
Boundaries can be added to a map using an array of long/lat pairs:

<pre><code>
<%= gmap :gmapid => 'bdry', :width => 500, :height => 200,
         :lat => 37.319, :long => -122.017, :zoom => 12 %>

<%= gline :gmapid => 'bdry',
          :line => [ [-122.0322, 37.3344], 
                     [-122.0217,  37.3343], 
                     [-121.9955, 37.3208], 
                     [-121.9963,  37.3090], 
                     [-122.0077, 37.3104], 
                     [-122.0214, 37.3095], 
                     [-122.0322, 37.3124], 
                     [-122.0322, 37.3344] ] %>
</code></pre>

<%= gmap :gmapid => 'bdry', :width => 500, :height => 200,
         :lat => 37.319, :long => -122.017, :zoom => 12 %>

<%= gline :gmapid => 'bdry',
          :line => [ [-122.0322, 37.3344], 
                     [-122.0217,  37.3343], 
                     [-121.9955, 37.3208], 
                     [-121.9963,  37.3090], 
                     [-122.0077, 37.3104], 
                     [-122.0214, 37.3095], 
                     [-122.0322, 37.3124], 
                     [-122.0322, 37.3344] ] %>

<br />
<h3>Multimedia Maps</h3>
A map with icons, photos and videos that are embedded in pop-ups can be added like this (a couple of youtube videos):

<pre><code>
<%= gmap :gmapid => 'videomap', :marker => false,
       :width => 700, :height => 400,
       :lat => 36.72, :long => -118.9, :zoom => 12 %>   

<%= gmarker :gmapid => 'videomap', 
       :lat => 36.7032012939453, :long => -118.797996520996,
       :icon => '/images/Video.png',
       :shadow => 'images/Shadow.png',
       :thumbnail => 'http://img.youtube.com/vi/qSyNLfSX2TQ/2.jpg',
       :content => '<h2>Weaver Lake</h2>' + 
'<object width="280" height="230"><param name="movie" value="http://www.youtube.com/v/qSyNLfSX2TQ"></param><embed src="http://www.youtube.com/v/qSyNLfSX2TQ" type="application/x-shockwave-flash" width="280" height="230"></embed></object>'
 %>
</code></pre>

<%= gmap :gmapid => 'videomap', :marker => false,
       :width => 700, :height => 400,
       :lat => 36.72, :long => -118.9, :zoom => 12 %>   

<%= gmarker :gmapid => 'videomap', 
       :lat => 36.7032012939453, :long => -118.797996520996,
       :icon => '/images/Video.png',
       :shadow => 'images/Shadow.png',
       :thumbnail => 'http://img.youtube.com/vi/qSyNLfSX2TQ/2.jpg',
       :content => '<h2>Weaver Lake</h2>' + 
'<object width="280" height="230"><param name="movie" value="http://www.youtube.com/v/qSyNLfSX2TQ"></param><embed src="http://www.youtube.com/v/qSyNLfSX2TQ" type="application/x-shockwave-flash" width="280" height="230"></embed></object>'
 %>

<%= gmarker :gmapid => 'videomap', 
       :lat => 36.7100982666016, :long => -118.811996459961,
       :icon => '/images/Video.png',
       :shadow => 'images/Shadow.png',
       :thumbnail => 'http://img.youtube.com/vi/5HZUUHxmhwg/2.jpg',
       :content => '<h2>Weaver Lake Trail</h2>' + 
'<object width="280" height="230"><param name="movie" value="http://www.youtube.com/v/5HZUUHxmhwg"></param><embed src="http://www.youtube.com/v/5HZUUHxmhwg" type="application/x-shockwave-flash" width="230" height="230"></embed></object>'
 %>

<%= gmarker :gmapid => 'videomap', 
       :lat => 36.7482986450195, :long => -118.974998474121,
       :icon => '/images/Video.png',
       :shadow => 'images/Shadow.png',
       :thumbnail => 'http://img.youtube.com/vi/-OFS3mqEuW8/2.jpg',
       :content => '<h2>General Grant Tree Interview</h2>' + 
'<object width="280" height="230"><param name="movie" value="http://www.youtube.com/v/-OFS3mqEuW8"></param><embed src="http://www.youtube.com/v/-OFS3mqEuW8" type="application/x-shockwave-flash" width="280" height="230"></embed></object>'
 %>

<%= gmarker :gmapid => 'videomap', 
       :lat => 36.7498016357422, :long => -118.97200012207,
       :icon => '/images/Video.png',
       :shadow => 'images/Shadow.png',
       :thumbnail => 'http://img.youtube.com/vi/7n1VpiS3f1o/2.jpg',
       :content => '<h2>General Grant Tree</h2>' + 
'<object width="285" height="230"><param name="movie" value="http://www.youtube.com/v/7n1VpiS3f1o"></param><embed src="http://www.youtube.com/v/7n1VpiS3f1o" type="application/x-shockwave-flash" width="280" height="230"></embed></object>'
 %>

<%= gmarker :gmapid => 'videomap', 
       :lat => 36.7117004394531, :long => -118.817001342773,
       :icon => '/images/Video.png',
       :shadow => 'images/Shadow.png',
       :thumbnail => 'http://img.youtube.com/vi/thyu_UXTdzE/2.jpg',
       :content => '<h2>Weaver Lake Trailhead</h2>' + 
'<object width="280" height="230"><param name="movie" value="http://www.youtube.com/v/thyu_UXTdzE"></param><embed src="http://www.youtube.com/v/thyu_UXTdzE" type="application/x-shockwave-flash" width="280" height="230"></embed></object>'
 %>
=end

  def gmap( options = {} )
    opt = defaults.merge( options ) 
    str = google_script( opt ) + mapdiv( opt  )
    str << gmarker( opt  ) if opt[:marker]
    str
  end
  
  def gmarker( opt = {}  )
    return "gmarker requires ':gmapid' parameter!" if !opt[:gmapid]
    content = opt[:content] ? opt[:content].gsub!( /"/, '\\"' ) : nil
    if ! opt[:address]
      content_tag( :script,
        "google_map_icon_js( #{opt[:gmapid]}, " + 
        "#{opt[:long]},#{opt[:lat]},\"#{content}\", \"#{opt[:icon]}\", \"#{opt[:shadow]}\", \"#{opt[:thumbnail]}\" );",
          { :type => "text/javascript" } ) + "\n"          
    else
      content_tag( :script,
        "google_map_icon_by_adr_js( #{opt[:gmapid]}, " +
        "'#{opt[:address]}',\"#{content}\", \"#{opt[:icon]}\", \"#{opt[:shadow]}\", \"#{opt[:thumbnail]}\" );",
          { :type => "text/javascript" } ) + "\n"                
    end
  end  
  
  def gline( opt = {} )
    return "gmarker requires ':gmapid' parameter!" if !opt[:gmapid]
    content = opt[:content] ? opt[:content] : nil
    line = "google_map_boundary_add_js( bdry, ["
    opt[:line].each do |pnt|
      line << "new GLatLng(#{pnt[1]},#{pnt[0]}),"
    end if opt[:line]
    line.chop!
    line << "] );"
    content_tag( :script, line ,
        { :type => "text/javascript" } ) + "\n"        
  end
  
private

  def defaults
    { :width => "200", 
      :height => "200",
      :long => "-122.01686382293701",
      :lat => "37.31932181336203",
      :zoom => "15",
      :marker => true,
      :key => @wiki.config[:google_key],
      :gmapid => 'gmap' + rand(10000).to_s  }
  end
  
  def google_script( opt )
    content_tag( :script, "",
        { :type => "text/javascript",
          :src => "http://maps.google.com/maps?file=api&v=2&key=#{opt[:key]}" } ) + "\n"
  end    
   

  
  def mapdiv( opt )
    div_style = "width:#{opt[:width]}px;height:#{opt[:height]}px;"
    if ! opt[:address]
      embed_script = "var #{opt[:gmapid]} = google_map_js( '#{opt[:gmapid]}', " +
                       "#{opt[:long]},#{opt[:lat]},#{opt[:zoom]} );"
    else
      embed_script = "var #{opt[:gmapid]} = google_map_by_adr_js( '#{opt[:gmapid]}', " +
                       "'#{opt[:address]}',#{opt[:zoom]} );"
    end                                                  
    content_tag( :div, "",
                 { :id => opt[:gmapid],
                   :style => div_style } ) + "\n" +
    content_tag( :script, embed_script, { :type=>"text/javascript" } ) + "\n"
  end   

end


=begin
(Check application.js for possible more current version of the js code:)
function google_map_js( div, lat, long, zoom ) { 
  map = new GMap2(document.getElementById(div)); 
  var point = new GLatLng(long,lat);  
  map.setCenter(point,zoom); 
  map.addControl(new GSmallMapControl(),  
                     new GControlPosition(G_ANCHOR_BOTTOM_RIGHT, new GSize(10, 10)));  
  return map;
} 
function google_map_by_adr_js( div, address, zoom ) { 
  var map = new GMap2(document.getElementById(div));
  map.addControl(new GSmallMapControl(),
                 new GControlPosition(G_ANCHOR_BOTTOM_RIGHT, new GSize(10, 10)));
  var geocoder = new GClientGeocoder();        
  geocoder.getLatLng( address,
    function(pnt) { 
      if (!pnt) { alert( address + " not found" ); }
      else { map.setCenter(pnt,zoom); }
      } );  
  return map;  
} 
function google_map_icon_add_js( map, point, content ) {
  var icon = new GIcon(); 
  icon.shadow = 'http://www.google.com/intl/en_ALL/mapfiles/arrowshadow.png'; 
  icon.iconAnchor = new GPoint(10, 10); 
  icon.image = 'http://www.google.com/intl/en_ALL/mapfiles/arrow.png'; 
  icon.infoWindowAnchor = new GPoint(10, 10);	 
  icon.iconSize = new GSize(50, 30); 
  icon.shadowSize = new GSize(50, 30); 
  var marker = new GMarker(point, icon);
  if ( content ) GEvent.addListener(marker, "click", function() {
                     marker.openInfoWindowHtml(content); });
  map.addOverlay(marker);
}

function google_map_icon_js( map, lat, long, content ) { 
  var point = new GLatLng(long,lat); 
  google_map_icon_add_js( map, point, content );
}
function google_map_icon_by_adr_js( map, address, content ) { 
  var geocoder = new GClientGeocoder();        
  geocoder.getLatLng( address,
    function(point) { 
      if (!point) { alert( address + " not found" ); }
      else { google_map_icon_add_js( map, point, content ); }
      } );    
}
function google_map_boundary_add_js( map, points ) {
  var pline = new GPolyline( points ); 
  map.addOverlay(pline);
}

=end