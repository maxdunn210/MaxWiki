require 'erb'
require 'open-uri'
require 'mime/types'
require 'uri'
require 'fileutils'
require 'maxwiki_convert'
require 'webdav'

class MaxwikiInclude
  
  class << self
    
    def html(uri, username=nil, password=nil, conversion_type = nil, jooconverter=nil)
      
      # Generate the basic information. Even for existing records, the conversion_type might have changed.
      begin
        uri_path = URI::parse(uri).path
      rescue
        return format_error("The url '#{uri}' is not correct")
      end
      base_name = URI::unescape(File.basename(uri_path))
      suffix = conversion_type ? conversion_type : File.suffix(base_name)
      mime_type = MIME::Types.type_for(".#{suffix}")[0] || MIME::Types['application/octet-stream'][0]
      
      # If no wiki_file record, create it. Otherwise update the source_type because this might change through 
      # setting 'conversion_type' to override the suffix
      wiki_file = WikiFile.find_by_source_uri(uri)
      if wiki_file.nil?
        wiki_file = WikiFile.create(:source_uri => uri, :source_type => mime_type.content_type, :file_name => base_name)
      else
        wiki_file.update_attribute(:source_type, mime_type.content_type) if wiki_file.source_type != mime_type.content_type
      end
      
      # Determine if we need to download and convert the file
      # Currently, we only download if we need to convert it
      if MaxwikiConvert::mime_types.include?(wiki_file.source_type) 
        
        error = download(wiki_file, username, password)
        return error if error
        
        error = convert(wiki_file, jooconverter)
        return error if error
      end  
      
      # Now figure out what we have
      if !wiki_file.converted_path.blank?
        uri = make_cache_uri(wiki_file.converted_path)
        mime_type = MIME::Types[wiki_file.converted_type][0]
      elsif !wiki_file.cache_path.blank?
        uri = make_cache_uri(wikie_file.cache_path)
        mime_type = MIME::Types[wiki_file.source_type][0]
      else
        uri = wiki_file.source_uri
        mime_type = MIME::Types[wiki_file.source_type][0]
      end

      case mime_type.content_type
      when 'text/html': include_html(uri)
      when 'application/pdf': include_pdf(uri)
      when 'text/plain': include_text(uri, username, password)
      else 
        case mime_type.media_type 
        when 'video': include_quicktime(uri)
        when 'image': include_image(uri)
        else unknown_type(uri) 
        end
      end
    end
    
    #-------------------
    private
    
    # download if needed    
    def download(wiki_file, username, password)
      if wiki_file.cache_path.nil?
        cache_dir = File.join('_inc', get_wiki_file_next_num.to_s)
        cache_path =  File.join(cache_dir, wiki_file.file_name)
        wiki_file.update_attributes(:cache_path => cache_path)
      end  
      
      webdav = Webdav.new(wiki_file.source_uri, username, password)
      return format_error(webdav.error_msg) if webdav.error?
      
      # Check if the file is new or has changed
      if !File.exist?(make_cache_abs(wiki_file.cache_path)) || needs_update(wiki_file, webdav)
        
        # Create the directory path if necessary
        # This is needed the first time the file is retrieved, or after a global cache clear
        FileUtils.mkdir_p(make_cache_abs(File.dirname(wiki_file.cache_path)))
        
        # Do a sanity check on the converted_path, and then delete all the converted files so they will be recreated
        unless wiki_file.converted_path.blank?
          dirname = File.dirname(make_cache_abs(wiki_file.converted_path))
          if dirname =~ /_inc\/\d+$/
            FileUtils.rm_rf(Dir.glob(dirname+ '/*'))
          end
        end
        
        # get the file and record information
        webdav.get(wiki_file.source_uri)
        return format_error("Error retrieving #{wiki_file.source_uri}: " + webdav.error_msg) if webdav.error?
        
        # On BlueBox, files were being created with public write access. So make sure that doesn't happen
        old_umask = File.umask(0022)
        File.open(make_cache_abs(wiki_file.cache_path), 'w') {|f| f.print(webdav.result.body)}
        File.umask(old_umask)
        
        change_type = wiki_file.detect_change_type || ['etag', 'date'].find {|type| !webdav.result.header[type].blank?}
        wiki_file.update_attributes(:detect_change_type => change_type, :detect_change_marker => webdav.result.header[change_type])
        
        return nil
      end
    end
    
    # Convert if needed 
    def convert(wiki_file, jooconverter)     
      if wiki_file.converted_path.blank? || !File.exists?(make_cache_abs(wiki_file.converted_path))
        converter = MaxwikiConvert.new(jooconverter)
        converter.convert_to_html(make_cache_abs(wiki_file.cache_path))
        return format_error(converter.error_msg) unless converter.error_msg.nil?
        
        uri = File.join(File.dirname(wiki_file.cache_path), File.basename(converter.converted_path))
        mime_type = MIME::Types.type_for(".#{File.suffix(converter.converted_path)}")[0] 
        wiki_file.update_attributes(:converted_path => uri, :converted_type => mime_type.content_type)
        return nil
      end
    end
    
    def make_cache_uri(cache_path)
      abs_cache_path = File.expand_path(File.join(ActionController::Base.page_cache_directory, cache_path))
      abs_rails_public = File.expand_path("#{RAILS_ROOT}/public")
      if abs_cache_path =~ /^#{abs_rails_public}(.*)/
        $1
      elsif abs_cache_path =~ /vendor\/plugins\/maxwiki_convert\/test(.*)/  # for testing
        $1
      else
        abs_cache_path
      end
    end  
    
    def make_cache_abs(cache_path)
      File.join(ActionController::Base.page_cache_directory, cache_path)
    end
    
    def get_wiki_file_next_num
      Wiki.transaction do
        WikiFile.current_wiki.reload
        WikiFile.current_wiki.lock! unless Rails::VERSION::STRING.starts_with?('1.1')
        WikiFile.current_wiki.wiki_file_next_num += 1
        WikiFile.current_wiki.save!
      end
      WikiFile.current_wiki.wiki_file_next_num
    end
    
    def needs_update(wiki_file, webdav)
      return true if wiki_file.detect_change_marker.blank?
      
      webdav.head(wiki_file.source_uri)
      return wiki_file.detect_change_marker != webdav.result.header[wiki_file.detect_change_type]
    end
    
    def unknown_type(uri)
      format_error("Unknown type for '#{uri}'")
    end
    
    def format_error(msg)
      "<p>#{msg}</p>\n"
    end
    
    def converted_url(file_path)
      "cache/" + File.basename(file_path)
    end 
    
    def unescaped_uri_path(uri)
      path = URI::parse(URI::encode(uri)).path rescue ''
      URI::unescape(path)
    end
    
    def include_text(uri, username=nil, password=nil)
      unless username.nil?
        options = {}
        options[:http_basic_authentication] = [username, password] 
      end
      text = open(uri, options).read
      "<div class='scroll_area'>\n<code><pre>\n" + ERB::Util.html_escape(text) + "\n</pre></code>\n</div>\n"
    end
    
    def include_html(uri)    
      iframe_tag(uri, '100%', '500px')
    end
    
    def include_pdf(uri)    
      iframe_tag(uri, '620px', '820px')
    end
    
    def include_image(uri)
      %Q{<img src="#{uri}" alt="#{File.basename(unescaped_uri_path(uri), '.*')}" />}
    end
    
    def include_quicktime(uri)
       <<-EOF
         <embed src="#{uri}" 
         width="100%" height="500px" autoplay="false"  scale="aspect">
         </embed>
       EOF
    end
    
    def iframe_tag(uri, width, height)
      #      <iframe style="overflow:visible "marginwidth="0" marginheight="0" name="ifrm" id="ifrm" 
      #        src="#{converted_url}" 
      #        onload="setIframeHeight('ifrm')" 
      #        width="100%" height="500px" frameborder="0" scrolling="auto">
      #      Sorry, your browser can't show this document directly (it doesn't support iframes). 
      #      Here is a <a href="#{converted_url}">link to #{File.basename(file_path)}</a>
      #      </iframe>
      #      
       <<-EOF
        <iframe style="overflow:visible "marginwidth="0" marginheight="0" name="ifrm" id="ifrm" 
          src="#{uri}" 
          onload="setIframeHeight('ifrm')" 
          width=#{width} height=#{height} frameborder="0" scrolling="auto">
        Sorry, your browser can't show this document directly (it doesn't support iframes). 
        Here is a <a href="#{uri}">link to #{File.basename(uri)}</a>
        </iframe>
      EOF
    end
    
    def object_tag(uri)    
       <<-EOF
         <object type="text/html" data="#{file_path}" 
         width="100%" height="500px">
          <a href="#{file_path}">You are using a very old browser.
           Click here to go directly to included content.</a>
         </object>
       EOF
    end
    
  end
end