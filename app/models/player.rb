# Schema as of Wed Apr 05 20:13:53 Pacific Daylight Time 2006 (schema version 7)
#
#  id                  :integer(11)   not null
#  household_id        :integer(11)   default(0), not null
#  firstname           :string(50)    default(), not null
#  lastname            :string(50)    default(), not null
#  birthday            :date          not null
#  years_exp           :integer(11)   
#  lastlevel           :string(20)    
#  grade               :string(20)    
#  school              :string(40)    
#  teacher             :string(40)    
#  note                :string(255)   
#  shirtsize           :string(20)    
#  pantsize            :string(20)    
#  limitation          :string(100)   
#  allergies           :string(100)   default(), not null
#  age_checked         :boolean(1)    
#  waiver_required     :boolean(1)    
#  fee_paid            :float         default(0.0)
#  fee_paid_on         :date          
#  fee_paid_by         :string(255)   
#  created_at          :datetime      
#  updated_at          :datetime      
#  referred_by         :string(255)   
#  team_id             :integer(11)   
#

class Player < MaxWikiActiveRecord
  
  include NameHelper
  
  belongs_to :wiki
  belongs_to :household
  belongs_to :team
  validates_presence_of :limitation, :message => "- Please check one option"
  
  #prevent form injection. See comments in player_update_protected in register_controller.rb
  attr_protected :user_id, :fee_paid, :age_checked, :waiver_required, :address_checked, :signed_form_received
  
  SIBLING_DISCOUNT = 0
  attr_accessor :gross_fee
  attr_accessor :sibling_discount
  attr_accessor :earlybird_discount
  attr_accessor :late_fee
  attr_accessor :net_fee
  attr_reader :fee_paid
  
  def fee_paid
    fee = read_attribute("fee_paid")
    if fee.nil?
      fee = 0
    end
    return fee
  end
  
  def league_age(season=2011)
    if birthday.month > 4
      season - birthday.year - 1
    else
      season - birthday.year
    end
  end
  
  def fee
    # Fall ball: 60
    if league_age <= 6
      100
    elsif league_age <= 8
      140
    elsif league_age <= 12
      160
    else
      180
    end
  end
  
  def early_bird_fee
    # Fall ball: 60
    if league_age <= 6
      80
    elsif league_age <= 8
      120
    elsif league_age <= 12
      140
    else
      160
    end
  end
  
  def fee_today
    # The server is in PST, so compare against that time zone
    month = 1
    day = 1
    year = 2011
    if Time.now < Time.local(0,0,0,month,day,year,0,0,false,'PST')
      early_bird_fee
    else
      fee
    end
  end
  
  def late_fee
    # The server is in EST, so compare against that time zone
    month = 2
    day = 3
    year = 2011
    if Time.now < Time.local(0,0,0,month,day,year,0,0,false,'PST')
      0
    else
      # Late fee used to be 10
      0
    end
  end  
  
  def Player.calc_all_fees(players)
    sibling_discount = 0
    players.each do |p| 
      if p.fee_paid == 0
        p.gross_fee = p.fee
        p.sibling_discount = sibling_discount
        p.earlybird_discount = p.fee - p.fee_today 
        p.net_fee = p.gross_fee - p.sibling_discount - p.earlybird_discount + p.late_fee
        sibling_discount = SIBLING_DISCOUNT
      else
        p.gross_fee = 0
        p.sibling_discount = 0
        p.earlybird_discount = 0
        p.net_fee = 0 
      end
    end
  end
  
  def Player.find_all_by_user(user, *other_conditions)
    return nil if user.nil?
    
    conditions = ['household_id = ?', user.household_id]
    conditions[0] << ' and (fee_paid > 0)' if other_conditions.include?(:fee_paid)
    if other_conditions.include?(:info_checked)
      conditions[0] << ' and (info_checked = ?)' 
      conditions << true
    end
    
    find(:all, :conditions => conditions)
  end
  
end
