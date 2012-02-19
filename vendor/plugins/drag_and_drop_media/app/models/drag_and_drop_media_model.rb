require 'xmlrpc/client'
require 'rexml/document'
require 'open-uri'

class DragAndDropMediaModel
  
  attr_reader :display_name, :tags, :user, :page, :per_page, :on
  
  # initialize client instance, and set parameters to nil
  # note that success does not indicate that api_key is ok 
  def initialize( name, per_page = 8, default_tag = 'okapi' )
    @display_name = name
    @api_key = @api_path = @api_index = nil
    @on = false
    @dirty = true
    @tags = default_tag
    @user = @items = nil
    @page = 1
    @per_page = per_page
  end
  def visible!
    @on = true
  end	
  def toggle
    @on = !@on
  end	
  def forward
    @page += 1
    @dirty = true
  end
  def backward
    if @page > 1
      @page -= 1
      @dirty = true
    end
  end
  def update (tags, user)
    @page = 1
    @tags = tags
    @user = user
    @dirty = true
  end 
  
  def search(tags=@tags,user=@user,page=@page)
    if  @tags == tags && @page == page && @user == user && !@dirty
      return @items
    end
    @dirty = false
    @tags = tags
    @user = user
    @page = page
    @items = search_implementation( @tags, @user, @page, @per_page ) 
    if @items && @items.size > @per_page
      @items = @items[((@page-1)*@per_page)..(@page*@per_page-1)]   
    end
    return @items
  end
  
  def xmlrpc_client(host,path,port)
    XMLRPC::Client.new(host,path,port)
  end
  def xmlrpc_get_xml(method,args,item_string)
    str = @api_path.call(method,args)
    res = REXML::Document.new(str)
    items = res.root.elements.to_a(item_string)
  end
  def uri_get_xml(args,item_str)
    req = @api_path.dup
    args.each do |x| 
      req << x[0] + '=' + x[1] + '&' 
    end
    req.gsub!(/&\Z/,'')
    lines = nil
    open( req ) { |file| lines = file.read }
    res = REXML::Document.new( lines )	
    return res.root.get_elements(item_str)
  end
  def uri_get_response(args)
    req = @api_path.dup
    args.each do |x| 
      req << x[0] + '=' + x[1] + '&' 
    end
    req.gsub!(/&\Z/,'')
    lines = nil
    open( req ) { |file| lines = file.read }
    return lines
  end	
  # this is for testing and needs to be overridden
  def search_implementation( tags, user, page, per_page )
    if tags == 'testtag'
      items = []
      1.upto(20) {|i| items<< ('tag_'+i.to_s)}
      return items
    elsif user == 'testuser'
      items = []
      1.upto(20) {|i| items<< ('user_'+i.to_s)}
      return items
    elsif !user && !tags
      return nil
    else
      return []
    end	   
  end
  
end
