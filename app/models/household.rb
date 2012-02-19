# Schema as of Wed Apr 05 20:13:53 Pacific Daylight Time 2006 (schema version 7)
#
#  id                  :integer(11)   not null
#  address             :string(100)   
#  city                :string(100)   
#  zip                 :string(20)    
#  session_id          :string(80)    
#

class Household < MaxWikiActiveRecord

  belongs_to :wiki
  has_many :players
  has_one :doctor
  has_one :adult1, :class_name => "Adult", :conditions => "adultnum = 1"
  has_one :adult2, :class_name => "Adult", :conditions => "adultnum = 2"
  has_one :emer_contact, :class_name => "Adult", :conditions => "adultnum = 3"
  
  validates_presence_of :zip

end
