# Schema as of Wed Apr 05 20:13:53 Pacific Daylight Time 2006 (schema version 7)
#
#  id                  :integer(11)   not null
#  kind                :string(40)    
#  name                :string(40)    
#  short_name          :string(10)    
#  display_order       :integer(11)   
#  page_name           :string(100)   
#

class Lookup < MaxWikiActiveRecord

  belongs_to :wiki
  has_many :teams
  
  LEVEL = 'Level'
  LOCATION = 'Location'
  LEAGUE = 'League'
  
  def self.list_kinds
    Array[LEVEL, LOCATION, LEAGUE]
  end
  
  def self.find_all(kind)
    # Turn this off for now because with fastcgi, new items won't appear
    #@lookup_lists = {} unless defined? @lookup_lists
    #@lookup_lists[kind] ||= Lookup.find(:all, 
    Lookup.find(:all, 
      :conditions => "kind = '#{kind}'", 
      :order => "display_order, name")
  end

  def self.list(kind)
    Lookup.find_all(kind).map {|i| [i.name, i.id]}
  end
  
  def self.name_list(kind)
    Lookup.find_all(kind).map {|i| i.name}
  end
  
  def self.find_blank(kind)
    Lookup.find(:first, :conditions => "kind = '#{kind}' and (ISNULL(name) or LENGTH(name) = 0)")
  end    

end
