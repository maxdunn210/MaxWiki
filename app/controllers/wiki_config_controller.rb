class HashAsObject
  def initialize(hash)
    @hash = hash
  end
  
  def method_missing(method, *args)
    @hash[method]        
  end
end

class WikiConfigController < ApplicationController
  
  layout 'main'
  before_filter :authorize_admin
  
  def index
  end
  
  def config
    # Put all config variables in an object that option tag helpers can use
    @config = HashAsObject.new(@wiki.config)
    
    @config_template = params[:template]
    item = WIKI_CONFIG_ITEMS.find {|i| i[:template] == params[:template]}
    @config_title = item[:title] unless item.blank?
  end
  
  def update
    if request.post? && params[:config]
      params_using_symbols = params[:config].symbolize_keys
      
      # Turn the strings "boolean:true" and "boolean:false" into real boolean values
      # This is for check_box values that can only return integers or strings
      params_using_symbols.each do |key, value| 
        if value == 'boolean:true'
          params_using_symbols[key] = true
        elsif value == 'boolean:false'
          params_using_symbols[key] = false
        end
      end
      
      @wiki.config = {} if @wiki.config.nil?
      @wiki.config.merge!(params_using_symbols)
      
      if @wiki.save
        flash[:notice] = "Configuration saved"
        redirect_to :action => 'index'
      else
        flash[:error] = "Error: #{@wiki.errors.full_messages.to_sentence}"
        redirect_to :action => 'config', :template => params[:template]
      end
    end
  end
  
end

