require 'net/http'
require 'net/https'
require "rexml/document"

#-----------------
class WebdavItem
  attr_accessor :name, :href, :locked_by, :token, :properties
  attr_writer :directory, :checked_out, :locked, :locked_by_me
  
  def initialize(name, href, attributes = {})
    self.name = name
    self.href = URI.unescape(href)
    self.directory = attributes[:directory]
    self.checked_out = attributes[:checked_out]
    self.locked = attributes[:locked]
    self.locked_by_me = attributes[:locked_by_me]
    self.locked_by = attributes[:locked_by]
    self.token = attributes[:token]
    self.properties = attributes[:properties]
  end
  
  def directory?
    @directory
  end
  
  def checked_out?
    @checked_out
  end
  
  def locked?
    @locked
  end
  
  def locked_by_me?
    @locked_by_me
  end
  
  def <=>(other)
   (!self.directory?).to_s + self.name.downcase <=> (!other.directory?).to_s + other.name.downcase
  end
end

#-----------------
class Webdav
  
  attr_accessor :dir, :item, :lock_owner
  attr_reader :list, :request, :result, :result_xml, :properties
  
  PROPFIND_DISPLAYNAME = <<EOL
<?xml version="1.0" ?>
<propfind xmlns="DAV:">
 <prop>
  <displayname/>
 </prop>
</propfind>
EOL
  
  PROPFIND_ALLPROP = <<EOL
<?xml version="1.0" ?>
<propfind xmlns="DAV:">
 <allprop/>
</propfind>
EOL
  
  PROPFIND_DIR_LIST = <<EOL
<?xml version="1.0" ?>
<propfind xmlns="DAV:">
 <prop>
  <displayname/>
  <checked-out/>
  <checked-in/>
  <lockdiscovery/>
 </prop>
</propfind>
EOL
  
  PROPFIND_LOCK_TOKEN = <<EOL
<?xml version="1.0" ?>
<propfind xmlns="DAV:">
 <prop>
  <displayname/>
  <lockdiscovery/>
 </prop>
</propfind>
EOL
  
  REPORT_PPS = <<EOL
<?xml version="1.0" ?>
<acl-principal-prop-set  xmlns="DAV:">
 <prop>
  <displayname/>
 </prop>
</acl-principal-prop-set>
EOL
  
  LOCK = <<EOL
<?xml version="1.0" ?>
<lockinfo xmlns="DAV:">
<lockscope><exclusive/></lockscope>
<locktype><write/></locktype>
<owner>%s</owner>
</lockinfo>
EOL
  
  DEFAULT_LOCK_OWNER = 'MaxWiki'
  
  def initialize(href, username = nil, password = nil, lock_owner = nil, other_options = nil)
    uri = URI.parse(URI.escape(href))    
    @host = URI.unescape(uri.host)
    raise if @host.blank?
    @root_path = URI.unescape(uri.path)
    @root_path = '/' if @root_path.empty?
    @username = URI.unescape(uri.user) rescue username
  @lock_owner = lock_owner || @username || DEFAULT_LOCK_OWNER
    @password = URI.unescape(uri.password) rescue password
  @port = uri.port
    @server = "#{uri.scheme}://#{@host}"
    @server << ":#{@port}" if @port != uri.default_port
    @other_options = other_options
  rescue
    @last_error = "The server string '#{href}' is not correct"
  end
  
  def options(dir)
    @dir = dir
    send_request(Net::HTTP::Options)
  end
  
  def get(path)
    send_request(Net::HTTP::Get, path)
  end
  
  def head(path)
    send_request(Net::HTTP::Head, path)
  end
  
  def put(path, body, token = nil)
    headers = {}
    unless token.nil?
      headers[:If] = "<#{URI.escape(@server + path)}> (<#{token}>)"
    end
    send_request(Net::HTTP::Put, path, body, headers)
  end
  
  def delete(path)
    send_request(Net::HTTP::Delete, path)
  end
  
  def propfind(path)  
    send_request(Net::HTTP::Propfind, path, PROPFIND_DISPLAYNAME)
  end
  
  def report_pps(path)
    send_request(Net::HTTP::Report, path, REPORT_PPS)
  end
  
  def search(path, conditions = nil, properties = nil)
    xml = Builder::XmlMarkup.new  
    xml.instruct!
    xml.D :searchrequest,
  'xmlns:D' => "DAV:",
   'xmlns:C' => "http://www.xythos.com/documentClasses/1",
   'xmlns:S' => "http://www.xythos.com/namespaces/custom/",
   'xmlns:X' => "http://www.xythos.com/namespaces/StorageServer",
   'xmlns:K' => "com.kimpton.tickler" do
      xml.D :basicsearch do
        xml.D :select do
          xml.D :prop do
            xml.D :displayname
            if properties
              properties.each do |property|
                if property.include?('Tickler')
                  xml.K property.to_sym
                else
                  xml.C property.to_sym
                end
              end
            end
          end
        end
        xml.D :from do
          xml.D :scope do
            xml.D :href, URI.escape("#{@server}#{path}")
            xml.D :depth, 'infinity'
          end
        end
        if conditions
          xml.D :where do
            conditions.each do |condition|
              xml.D condition[1] do
                xml.D :prop do
                  xml.C condition[0]
                end
                xml.D :literal, condition[2]
              end
            end
          end
        end
      end
    end
    
    @properties = properties
    send_request(Net::HTTP::Search, path, xml.target!)
  end
  
  def lock(href)
    path = Webdav.parse_path(href)
    send_request(Net::HTTP::Lock, path, LOCK % @lock_owner)
  end
  
  def lock_query(href)
    path = Webdav.parse_path(href)
    send_request(Net::HTTP::Propfind, path, PROPFIND_LOCK_TOKEN)
    lock_attributes(@result_xml.elements['D:multistatus/D:response/D:propstat/D:prop'])
  end
  
  def get_lock_token(href, any_owner = nil)
    path = Webdav.parse_path(href)
    send_request(Net::HTTP::Propfind, path, PROPFIND_LOCK_TOKEN)
    if @last_error == 'Not Found'
      clear_error
      return nil
    end
    return nil if error?
    
    attributes = lock_attributes(@result_xml.elements['D:multistatus/D:response/D:propstat/D:prop'])
    unless attributes[:locked]
      @last_error = "File is not locked"
      return nil
    end
    
    if any_owner == :any_owner || attributes[:locked_by_me]
      token = attributes[:token]
    else
      @last_error = "File is locked by #{attributes[:locked_by]}"
      token = nil
    end
    token
  end
  
  def unlock(href, token)
    path = Webdav.parse_path(href)
    send_request(Net::HTTP::Unlock, path, '', 'Lock-Token' => "<#{token}>")
  end
  
  def dir_list(dir)
    @dir = dir
    send_request(Net::HTTP::Propfind, current_path, PROPFIND_DIR_LIST)
    return if error? || @result_xml.nil?
    
    @list = create_list
  end
  
  def search_list(dir, conditions = nil, properties = nil)
    @dir = dir
    # search(dir, SEARCH1 % URI.escape("#{@server}#{dir}"))
    search(current_path, conditions, properties)
    return if error? || @result_xml.nil?
    @list = create_list
  end
  
  def create_list
    list = []
    unless @dir.nil? || @dir == '/' || @dir == @root_path || (@other_options && @other_options[:no_up_dir])
      list << WebdavItem.new('.. (Up one directory)', up_dir, :directory => true) 
    end
    
    @result_xml.elements.each("D:multistatus/D:response") do |e|
      prop_element = e.elements["D:propstat/D:prop"]
      name = prop_element.elements["D:displayname"].text
      next if name.starts_with?('.')
      
      attributes = lock_attributes(prop_element)
      attributes[:properties] = {}
      prop_element.elements.each do |prop|
        unless prop.name == 'displayname'       
          if prop.has_text?
            attributes[:properties][prop.name] = prop.text
          else
            attributes[:properties][prop.name] = prop.entries.map {|entry| entry.text}.to_sentence
          end
        end
      end
      
      href = URI.unescape(e.elements["D:href"].text)
      attributes[:directory] = href.ends_with?('/')
      attributes[:checked_out] = prop_elements.elements["D:checked-out"].parent.parent.elements["D:status"].text.include?('200') rescue false
    
      
      # Don't include the current directory    
      if attributes[:directory]
        path = Webdav.parse_path(href)
        okay_to_add = (path != current_path)
      else
        okay_to_add = true
      end
      
      if okay_to_add
        list << WebdavItem.new(name, href, attributes)
      end
    end
    list.sort!
  end
  
  def error?
    !@last_error.blank?
  end
  
  def error_msg
    @last_error
  end
  
  def extended_error_msg
    @last_extended_error
  end
  
  def clear_error
    @last_error = nil
    @last_extended_error = nil
  end
  
  def current_path
    path_with_root(@dir)
  end
  
  #-----------------
  # Class methods
  #-----------------
  def Webdav.parse_path(href)
    path = URI.parse(URI.escape(href)).path
    if path.blank?
      return '/'
    else
      return URI.unescape(path)
    end
  rescue 
    return ''
  end
  
  def Webdav.parse_server(href)
    uri = URI.parse(URI.escape(href))
    if uri.scheme.blank?
      uri = URI.parse('http://' + URI.escape(href))
    end
    server = "#{uri.scheme}://#{uri.host}"
    server << ":#{uri.port}" if uri.port != uri.default_port
    return URI.unescape(server)
  rescue
    return ''
  end
  
  #---------------------
  private
  
  def lock_attributes(prop_element)
    attributes = {}
    lock_element = prop_element.elements['D:lockdiscovery/D:activelock']
    unless lock_element.nil?
      attributes[:locked] = true
      attributes[:locked_by] = lock_element.elements['D:owner'].text
      attributes[:locked_by_me] = (lock_element.elements['D:owner'].text == @lock_owner)
      attributes[:token] = lock_element.elements['D:locktoken/D:href'].text
    end
    attributes
  end
  
  def path_with_root(dir)
    path = "/#{dir}/".squeeze('/')
    if dir.blank? || !path.starts_with?(@root_path)
      path = "#{@root_path}#{path}"
    end
    path.squeeze('/')
  end
  
  def send_request(request_type, dir = nil, payload = '', headers = {})
    @request = nil
    @result = nil
    @result_xml = nil
    @item = nil
    clear_error
    
    @request = request_type.new(URI.escape(dir))
    @request['Content-Length'] = "#{payload.size}"
    @request['User-Agent'] = "MaxWiki 1.0"
    @request['Depth'] = '1' if request_type == Net::HTTP::Propfind
    @request['Overwrite'] = 'T'
    unless headers.blank?
      headers.each  {|key, value| @request[key.to_s] = value.to_s}
    end
    @request.basic_auth(@username, @password) unless @username.nil? || @username.empty?
    @request['Cookie'] ='XythosSessionID1=[B@4bf36b-1466195918'    
    
    http = Net::HTTP.new(@host, @port)
    
    # DEBUG
    #http.set_debug_output $stderr 
    # http.set_debug_output logger
    
    #http.verify_mode    = OpenSSL::SSL::VERIFY_NONE unless @ssl_strict
    #http.use_ssl        = true
    begin
      @result = http.request(@request, payload)   
      unless [Net::HTTPSuccess, Net::HTTPOK, Net::HTTPNoContent, Net::HTTPCreated].include?(@result.code_type)
        @last_error = @result.msg
        @last_extended_error = @result.body.match(/<body>(.*?)<\/body>/mi)[1] rescue nil
      return
      end
    rescue StandardError, Timeout::Error => e
      # logger.error(e)
      @last_error = "Error #{e} accessing #{dir}"
      return
    end  
    
    unless [Net::HTTP::Propfind, Net::HTTP::Options, Net::HTTP::Report, Net::HTTP::Search].include?(request_type)
      @result_xml = nil
    else
      @result_xml = REXML::Document.new(@result.body) unless error?
    end
  end
  
  def up_dir
    return '' if @dir.nil?
    
    slash_pos = @dir.chomp('/').rindex('/')
    if slash_pos.nil?
      ''
    else
      @dir[0, slash_pos]
    end      
  end
end

#-----------------
module Net
  class HTTP
    
    if not defined? Net::HTTP::Report
      class Report < HTTPRequest
        METHOD = 'REPORT'
        REQUEST_HAS_BODY = true
        RESPONSE_HAS_BODY = true
      end
    end
    
    if not defined? Net::HTTP::Search
      class Search < HTTPRequest
        METHOD = 'SEARCH'
        REQUEST_HAS_BODY = true
        RESPONSE_HAS_BODY = true
      end
    end
    
    def report(path, body = nil, initheader = {'Depth' => '0'})
      request(Report.new(path, initheader), body)
    end
    
    def search(path, body = nil, initheader = nil)
      request(Search.new(path, initheader), body)
    end
  end
end
