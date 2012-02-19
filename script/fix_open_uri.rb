require 'open-uri'

module OpenURI

  class << self
    alias maxwiki_original_open_http open_http
  end

  def OpenURI::open_http(buf, target, proxy, options)   
    unless target.nil? || !target.respond_to?(:user) || target.user.nil? || target.user.empty?
      options[:http_basic_authentication] = [URI::unescape(target.user), URI::unescape(target.password)] 
    end  
    
    maxwiki_original_open_http(buf, target, proxy, options)
  end
end
