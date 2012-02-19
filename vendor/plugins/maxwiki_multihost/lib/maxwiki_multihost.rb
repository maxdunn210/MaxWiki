# This module sets up the wiki based on what host is accessing it. It does this by looking through
# the MY_CONFIG[:host_map] hash. It also the caching directory based on the host so multi-hosted pages 
# will be kept separate.
# 
# These rules add the cache directory and take out port 80 if included. Then the change : to _ because 
# Linux and Windows don't like this in directory names:
# 
# Put these rules in .htaccess to find the cached pages:
# 
#  RewriteRule ^$ cache/%{HTTP_HOST}/index.html [QSA]
#  RewriteRule ^([^.]+)$ cache/%{HTTP_HOST}/$1.html [QSA]
#  RewriteRule ^(.*):80(.*)$ $1$2 [QSA]
#  RewriteRule ^(.*):(.*)$ $1_$2 [QSA]
#  RewriteCond %{REQUEST_FILENAME} !-f
#  RewriteRule ^(.*)$ dispatch.cgi [QSA,L]
#  
#  If instead you use the httpd.conf for configuration, use this variation:
#  
#  RewriteRule ^/?$ /cache/%{HTTP_HOST}/index.html [QSA]
#  RewriteRule ^/?([^.]+)$ /cache/%{HTTP_HOST}/$1.html [QSA]
#  RewriteRule ^(.*):80(.*)$ $1$2 [QSA]
#  RewriteRule ^(.*):(.*)$ $1_$2 [QSA]
#  RewriteCond %{DOCUMENT_ROOT}%{REQUEST_FILENAME} !-f
#  RewriteRule ^(.*)$ balancer://mongrel_cluster%{REQUEST_URI} [P,QSA,L]
# 
module MaxWiki
  module ApplicationControllerInclude
    
    def self.included(c)
      c.prepend_before_filter :wiki_setup
    end
    
    private
    
    # Look through the host_map table to find the wiki that it refers to
    # Also check to see if there are any other aliases the wiki might use and then 
    # redirect to the main host. This is necessary so caching will work.
    def get_name_or_redirect
      return '' if MY_CONFIG[:host_map].nil? 
      
      host_map = MY_CONFIG[:host_map].find do |m| 
        if m[:host].include?(':')
          request.host_with_port == m[:host].downcase
        else
          request.host == m[:host].downcase
        end  
      end
      
      name = nil
      if host_map.nil?
        text = "Unrecognized host: #{request.host_with_port}"
        logger.info text
        render :text => text, :status => 404
        
      elsif !host_map[:redirect_to].nil?
        headers["Status"] = "301 Moved Permanently"
        url = "http://#{host_map[:redirect_to]}#{request.request_uri}"
        redirect_to(url)
      else
        name = host_map[:name]
      end
      name
    end
    
    def wiki_setup
      @wiki_name = get_name_or_redirect
      return false if @wiki_name.nil? # if redirected or error, stop the pre_filter chain  
      
      # If @wiki_name empty, then there is no map table which means we are setup for only one host
      # so grab the first one
      if @wiki_name.blank?
        @wiki = Wiki.find(:first)
        @wiki_name = @wiki.name unless @wiki.nil?
      else 
        @wiki = Wiki.find_by_name(@wiki_name)
      end  
      
      # This uses wiki_scope.rb to limit all find, count and new to the current wiki
      # Set this even if only one wiki so that the wiki_id will be initialized correctly which will allow
      # this wiki to be merged into a multi_host later
      MaxWikiActiveRecord.current_wiki = @wiki
      
      host = request.host_with_port.gsub(':80','').gsub(':','_')
      ActionController::Base.page_cache_directory = "#{RAILS_ROOT}/public/cache/#{host}" 
    end
    
  end
end
