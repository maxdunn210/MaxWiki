
ActionController::Routing::Routes.draw do |map|

  map.connect 'maxwiki_gmap/show/:action/:id', :controller => "maxwiki_gmap/show"
    
  map.connect 'rss_with_headlines', :controller => 'wiki', :action => 'rss_with_headlines'
  map.connect 'rss_with_content', :controller => 'wiki', :action => 'rss_with_content'

  map.connect '_edit/:link', :controller => 'wiki', :action => 'edit'
  map.connect '_editt/:link', :controller => 'wiki', :action => 'edit', :editor => 'textile'
  map.connect '_editw/:link', :controller => 'wiki', :action => 'edit', :editor => 'wysiwyg'

  map.connect '', :controller => 'wiki', :action => 'show', :link => 'homepage'
  map.connect 'index.htm', :controller => 'wiki', :action => 'show', :link => 'homepage' 
  map.connect ':link', :controller => 'wiki', :action => 'show'
  map.connect '_action/wiki/:action/:link', :controller => 'wiki'
  map.connect '_action/wiki/show/:link', :controller => 'wiki', :action => 'show'
  
  map.connect '_action/:controller/:action/:id'
end
