require 'xmlrpc/client'
require 'rexml/document'

class MyYoutube

	def initialize
		@async = false
		@dev_id = "u8VJg3uvnM4"
        @secret = "blueokapi_utube"
		#@dev_id=MY_CONFIG[:youtube_dev_id]
		#@secret=MY_CONFIG[:youtube_secret]
		@endpoint='http://www.youtube.com/api2_xmlrpc'
		@tag = nil
		proto,host,port,path,user,pass=parse_url(@endpoint)
		raise "Unhandled protocol '#{proto}'" if proto.downcase != 'http'
		@client=XMLRPC::Client.new(host,path,port)
	end
    def dev_id()
	  @dev_id
	end
	def secret()
	  @secret
	end
	def get_profile(user)
	  args = {}
	  args['user'] = user
	  res = call_method('youtube.users.get_profile',args)
	  return res.elements["//first_name"].text, res.elements["//last_name"].text
	end
	def list_by_tag(tag='beyonce',per_page=10,page=1)
	  args = {}
	  #if  @tag == tag 
	  #  return @videos
	  #end
	  args['tag'] = @tag = tag
	  args['per_page'] = per_page
	  args['page'] = page
	  res = call_method('youtube.videos.list_by_tag',args)
	  @videos = res.root.elements.to_a("//video")
	  return @videos
	end
	def list_by_user(user='loveokapi')
	  args = {}
	  #if  @user == user
	  #  return @videos
	  #end
	  args['user'] = @user = user

	  res = call_method('youtube.videos.list_by_user',args)
	  @videos = res.root.elements.to_a("//video")
	  return @videos
	end
		   
  private
    def parse_url(url)
		url =~ /([^:]+):\/\/([^\/]*)(.*)/
		proto = $1.to_s
		hostplus = $2.to_s
		path = $3.to_s

		hostplus =~ /(?:(.*)@)?(.*)/
		userpass = $1
		hostport = $2
		user,pass = userpass.to_s.split(':',2)
		host,port = hostport.to_s.split(':',2)
		port = port ? port.to_i : 80

		return proto,host,port,path,user,pass
	end
	def call_method(method,args={})
		tries = 3
		args = args.dup
	    args['dev_id'] = @dev_id
		begin
			tries -= 1;
			str = @async ? @client.call_async(method,args) :
				@client.call(method,args)
			return REXML::Document.new(str)
		rescue Timeout::Error => te
	        logger.error "Timed out, will try #{tries} more times."
			if tries > 0
				retry
			else
				raise te
			end
		rescue REXML::ParseException
			return REXML::Document.new('<rsp>'+str+'</rsp>').
				elements['/rsp']
		rescue XMLRPC::FaultException => fe
			logger.error "ERR: #{fe.faultString} (#{fe.faultCode})"
			raise fe
		end
	end
end