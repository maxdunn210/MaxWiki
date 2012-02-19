require 'rexml/document'
require 'drag_and_drop_media_model'

class DragAndDropAmazon < DragAndDropMediaModel
  
  # of course tags=title search terms, and user=author
  
  AMAZON_PER_PAGE = 10 if !defined? AMAZON_PER_PAGE
  def initialize( name, amz_key = nil, default_tag = nil, 
                 index = nil, default_width = 180 )
    @width = default_width
    super( name, AMAZON_PER_PAGE, default_tag )
    @api_index = index
    @on = false
    @api_key = amz_key
    @api_path='http://webservices.amazon.com/onca/xml?'
  end
  
  #NOTE: Amazon now needs a signed signature in order to process. here is some sample code to do this
=begin 

require 'rubygems' 
require 'net/http' 
require 'uri' 
require 'openssl' 
require 'base64' 


request_URL_Http  = " http://ecs.amazonaws.jp/onca/xml?"

request_Opt = Hash.new 
request_Opt = { 
  "Service"        => "AWSECommerceService", 
  "Operation"      => "ItemSearch", 
  "ResposeGroup"   => "Medium", 
  "SearchIndex"    => "Books", 
  "Keywords"       => "Harry Potter", 
  "AWSAccessKeyId" => "***********", 
  "Version"        => "2009-10-01", 
  "Timestamp" => Time.now.gmtime.strftime('%Y-%m-%dT%H:%M:%SZ') 
} 
awsSecretKey = '***************' 
request_SortAndEncode = request_Opt.to_a.sort.map { |key, value| 
  URI.escape(key, /[^-_.!~*'()a-zA-Z\d;\/?@&=+$,\[\]]/n) + 
  "=" + 
  URI.escape(value, /[^-_.!~*'()a-zA-Z\d;\/?@&=+$,\[\]]/n) 
}.join("&") 

encoded_str = "GET\n" + "webservices.amazon.co.jp\n" + 
              "/onca/xml\n" + request_SortAndEncode 

signature = URI.escape( 
             Base64.encode64( 
              OpenSSL::HMAC::digest( 
               OpenSSL::Digest::SHA1.new, awsSecretKey, encoded_str)), 
               /[^-_.!~*'()a-zA-Z\d;\/?@&=+$,\[\]]/n) 

request = request_URL_Http + request_SortAndEncode + 
          "&Signature=" + signature 

# 
# for DEBUG 
# 
printf "\nencoded_str = \n%s\n", encoded_str 
printf "\nrequest_SortAndEncode = %s\n", request_SortAndEncode 
printf "\nrequest = " + request 
=end

  def search_implementation(tags,user,page,per_page)
    # user and per_page are ignored
    if (user !=nil && user.size>0) || per_page != AMAZON_PER_PAGE
      logger.error('DragAndDropAmazon::search_implementation parameter error 1')
      return nil
    end
    tags.gsub!(/\s/,'+')
    if @api_index != 'Books' && @api_index != 'Music'
      logger.error('DragAndDropAmazon::search_implementation parameter error 2')
      return nil
    end
    options = { 'Service' => 'AWSECommerceService',
	              'AWSAccessKeyId' => @api_key,
                  'Operation' => 'ItemSearch',
                  'Keywords' => tags,
                  'SearchIndex' => @api_index,
                  'ItemPage' => page.to_s,
                  'ResponseGroup' => 'Images,Small' }
    amzitems = uri_get_xml( options, '//Item')
    if amzitems.blank?
      ActionController::Base.logger.error("DragAndDropAmazon::search_implementation returned no items for '#{tags}'")
      return nil
    end
    
    items = []
    for itm in amzitems
      it = {}
      url = itm.elements["DetailPageURL"].text
      it[:asin] = itm.elements["ASIN"].text
      if itm.elements["ItemAttributes/Author"]
        it[:creator] = itm.elements["ItemAttributes/Author"].text
      elsif itm.elements["ItemAttributes/Artist"]
        it[:creator] = itm.elements["ItemAttributes/Artist"].text
      elsif itm.elements["ItemAttributes/Creator"]
        it[:creator] = itm.elements["ItemAttributes/Creator"].text   
      else
        it[:creator] = 'unspecified'
      end
      it[:title] = itm.elements["ItemAttributes/Title"].text
      if itm.elements["SmallImage/URL"]
        it[:thumb] = itm.elements["SmallImage/URL"].text    
        it[:thumb_width] = itm.elements["SmallImage/Width"].text   
        it[:thumb_height] = itm.elements["SmallImage/Height"].text   
      else
        if @api_index == "Books"          
          it[:thumb] = 'book.jpg'
        elsif @api_index == "Music"  
          it[:thumb] = 'music.jpg'
        else
          it[:thumb] = nil
        end
        it[:thumb_width] = 50
        it[:thumb_height] = 50
      end
      if itm.elements["LargeImage/URL"]
        img = itm.elements["LargeImage/URL"].text        
      else        
        img = it[:thumb]
      end
      it[:html] = html_code(url, it[:title], it[:creator], it[:thumb])
      items << it
    end
    return items
  end	
  
  private
  def html_code(url, title, creator, img) 
    str = %Q{<p>
      <a href="#{url}" target="_blank">
      <img align="left" 
      style="padding: 5px; margin-right: 5px;" 
      alt="#{title}" src="#{img}" />
      <strong>#{title}</strong></a><br />
      <em>by</em> #{creator}
      </p>
      <p>&nbsp;</p>
      <hr width="100%" size="2" style="clear: both;" />}
  end	 
  
end

# smoketest
=begin
d = WAmazon.new( :Amazon, "0XPTBGCTMB4S1B18QC82", 'rolling stones', 'Music' )

results = d.search
results.each do |r|
  puts r[:title]
end

results = d.search( 'pink floyd', nil, 3)
results.each do |r|
  puts r[:title]
end


d = WAmazon.new( :Amazon, "0XPTBGCTMB4S1B18QC82", 'Goethe', 'Books' )

puts
puts "searching for default, Goethe, in Books"
results = d.search
results.each do |r|
  puts r[:title]
end

puts
puts "searching for okapi in Books"
results = d.search( 'okapi', nil, 1)
results.each do |r|
  puts r[:title]
end
a = d.save
d = nil
d = WAmazon.renew(a)
results = d.search( 'okapi', nil, 1)
results.each do |r|
  puts r[:title]
end

=end