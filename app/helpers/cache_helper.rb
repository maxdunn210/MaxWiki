# These methods are in a helper because they need to be called from revision_sweeper.rb and 
# from admin_controller.rb when the user manually expires the cache
require 'fileutils'

module CacheHelper
  
  def expire_page_and_affected(page)
    # If a layout page, then expire all pages
    if MY_CONFIG[:layout_sections].include?(page.name)
      expire_all_pages
    else
      expire_page_and_references(page)
      expire_index_pages
    end  
  end
  
  # if pointing to a directory below public, then recursively delete all files
  # Otherwise, just recursively delete the html files
  def expire_all_pages
    cache_dir = File.expand_path(ActionController::Base.page_cache_directory)
    public_dir = File.expand_path("#{RAILS_ROOT}/public")
    if cache_dir =~ /^#{public_dir}\/\w+/
      FileUtils.rm_rf(Dir.glob(cache_dir+ '/*'))
    else
      expire_page(/.*\.html/)
    end
  end
  
  #------------
  private
  
  def expire_index_pages
    # Change to expire_page if page caching, expire_action otherwise  
    expire_page :controller => 'wiki', 
    :action => %w(authors recently_revised list)
    expire_page :controller => 'wiki', 
    :action => %w(rss_with_headlines rss_with_content)
  end   
  
  def expire_just_page(page_link)
    # Change to expire_page if page caching, expire_action otherwise
    expire_page :controller => 'wiki', 
    :action => 'show', :link => page_link
    
    # Also expire any subsequent blog pages
    expire_page(/#{page_link}__page_\d+\.html/)
  end
  
  def expire_page_and_parents(page)
    pages = [page]
    pages << page.parent unless page.parent.nil?
    pages << page.children unless page.children.blank?
    
    pages.flatten.each do |p|
      expire_just_page(p.link)
    end
  end
  
  def expire_page_and_related(page)
    expire_page_and_parents(page)
    
    # If a left or right page, also expire the main page
    main_page_link = page.link.dup
    if main_page_link.gsub!(/_left$/,'') or main_page_link.gsub!(/_right$/,'') 
      expire_page_and_parents(page)
    end  
  end  
  
  def expire_page_and_references(page)
    expire_page_and_related(page)
    WikiReference.pages_that_reference(page.name).uniq.each do |page_reference_name|
      # Have to find manually because @wiki is not initialized here
      referenced_page = Page.find(:first, :conditions => {:name => page_reference_name, :wiki_id => page.wiki_id})
      expire_page_and_related(referenced_page) unless referenced_page.nil?
    end      
  end    
end
