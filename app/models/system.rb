# Schema as of Wed Apr 05 20:13:53 Pacific Daylight Time 2006 (schema version 7)
#
#  id                  :integer(11)   not null
#  password            :string(60)    
#

class System < MaxWikiActiveRecord
  set_table_name 'system'
  
  cattr_accessor :storage_path, :logger
  self.storage_path = "#{RAILS_ROOT}/storage/"
  self.logger = RAILS_DEFAULT_LOGGER
  
  DEFAULT_NAME = 'maxwiki_system'
  DEFAULT_DESCRIPTION = 'MaxWiki System'

  def delete_wiki(name)
    wiki = Wiki.find_by_name(name)
    unless wiki.nil?
      wiki.destroy
    end
  end

  def storage_path
    self.class.storage_path
  end

  #---- Class methods -----  
  
  # Call this rather than creating the record directly because later it will do other things,
  # like create the host map table
  # This returns the System object created or updated if successful, nil otherwise
  def self.setup(params)
    system = System.find(:first)
    if system.nil?
      System.create(params)
    else
      ok = system.update_attributes(params)
      ok ? system : nil
    end
  end

end
