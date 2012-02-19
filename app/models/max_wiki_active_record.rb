class MaxWikiActiveRecord < ActiveRecord::Base
  
  include MaxWiki::MaxWikiActiveRecordInclude if defined? MaxWiki::MaxWikiActiveRecordInclude
  
  self.abstract_class = true
  cattr_accessor :current_wiki, :current_page_link, :system_read_only_mode, :system_read_only_msg
  
  def initialize(*args)
    super
    readonly! if @@system_read_only_mode
    self.wiki_id = @@current_wiki.id if @@current_wiki && respond_to?('wiki_id')
  end 
  
  def self.delete_all(*args)
    raise ReadOnlyRecord if @@system_read_only_mode
    super
  end
  
  def self.update_all(*args)
    raise ReadOnlyRecord if @@system_read_only_mode
    super
  end
  
  def self.system_read_only_msg
    @@system_read_only_msg || 'System is in read-only maintenance mode.'
  end
  
  #---------------------
  #private
  
  def self.find_every(options)
    if @@system_read_only_mode
      options = {} if options.nil?
      options[:readonly] = true
    end
    super(options)
  end
  
end