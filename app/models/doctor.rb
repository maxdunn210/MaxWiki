# Schema as of Wed Apr 05 20:13:53 Pacific Daylight Time 2006 (schema version 7)
#
#  id                  :integer(11)   not null
#  household_id        :integer(11)   default(0), not null
#  healthplan          :string(100)   default(), not null
#  policy_num          :string(40)    default(), not null
#  physician_name      :string(50)    default(), not null
#  physician_tel       :string(50)    default(), not null
#  physician_addr      :string(100)   default(), not null
#

class Doctor < MaxWikiActiveRecord

  belongs_to :wiki
  belongs_to :household
    
  include NameHelper
  
end
