# Schema as of Wed Apr 05 20:13:53 Pacific Daylight Time 2006 (schema version 7)
#
#  id                  :integer(10)   not null
#  email               :string(60)    default(), not null
#  firstname           :string(50)    
#  lastname            :string(50)    
#  household_id        :integer(11)   default(0), not null
#  home_phone          :string(20)    
#  work_phone          :string(20)    
#  cell_phone          :string(20)    
#  relationship        :string(50)    
#  adultnum            :integer(11)   default(0), not null
#  login               :string(80)    default(), not null
#  salted_password     :string(40)    default(), not null
#  salt                :string(40)    default(), not null
#  verified            :integer(11)   default(0)
#  role                :string(40)    
#  security_token      :string(40)    
#  token_expiry        :datetime      
#  deleted             :integer(11)   default(0)
#  delete_after        :datetime      
#

class Adult < MaxWikiActiveRecord

  belongs_to :wiki
  belongs_to :household
  
  #MD 9-Jan-2007 I don't think we really need these, and it messes up the migrations when importing NULL values
  #validates_length_of :home_phone, :maximum => 20, :message => '- Maximum length is %d'
  #validates_length_of :work_phone, :maximum => 20, :message => '- Maximum length is %d'
  #validates_length_of :cell_phone, :maximum => 20, :message => '- Maximum length is %d'
  
  include NameHelper
  
 end
