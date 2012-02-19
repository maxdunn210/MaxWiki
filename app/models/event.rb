# Schema as of Wed Apr 05 20:13:53 Pacific Daylight Time 2006 (schema version 7)
#
#  id                  :integer(11)   not null
#  kind                :string(40)    
#  name                :string(40)    
#  date_time           :datetime      
#  home_team_id        :integer(11)   
#  location_id         :integer(11)   
#  note                :string(200)   
#  length              :integer(11)   
#  visitor_team_id     :integer(11)   
#  home_team_note      :string(200)   
#  visitor_team_note   :string(200)   
#

class Event < MaxWikiActiveRecord
  
  belongs_to :wiki
  belongs_to :home_team, :class_name => "Team", :foreign_key => "home_team_id"
  belongs_to :visitor_team, :class_name => "Team", :foreign_key => "visitor_team_id"
  belongs_to :location, :class_name => "Lookup", :foreign_key => "location_id"
  
  GAME = 'Game'
  PRACTICE = 'Practice'
  EVENT = 'Event'
  
  # If the event is a Game or Practice, force the name to the same
  # If it is a general Event, leave the name alone since it will contain
  # the name of the event
  def check_and_assign_name(params)
    return if params[:event].nil? or params[:event][:kind].nil?
    
    if params[:event][:kind] =~ /GAME/i
      self[:name] = GAME
    elsif params[:event][:kind] =~ /PRACTICE/i
      self[:name] = PRACTICE
    end
  end
  
  # Check for conflicts except if no location, pointing to blank location, 
  # or no length
  def check_schedule_conflicts
    if length.nil? or length.zero?
      return nil
    elsif location.nil? or location.id <= 0 or location.name.to_s.empty?
      return nil 
    end
    
    # Find the events on the same day
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      conditions = ["location_id = ? and AGE(date_time, timestamp ?) < interval '1 day'", location.id, date_time.to_formatted_s(:db)]
    else
      conditions = ["location_id = ? and TO_DAYS(date_time) = TO_DAYS(?)", location.id, date_time.to_formatted_s(:db)]
    end
    conflicts = Event.find(:all, :order => "date_time", :conditions => conditions)
    
    d1 = d2 = date_time
    d2 = d1 + (length * 60)
    conflicts.map! do |event|
      if (id == event.id) 
        nil
      elsif (event.location.nil? or event.location.name.to_s.empty?)
        nil
      elsif (event.length.nil? or event.length.zero?)
        nil
      else
        e1 = e2 = event.date_time
        e2 = e1 + (event.length * 60)
        if (d1 >= e1 and d1 <  e2) or
         (d2 >  e1 and d2 <= e2) or
         (e1 >= d1 and e1 <  d2) or
         (e2 >  d1 and e2 <= d2)
          event
        else
          nil   
        end
      end  
    end
    
    conflicts.compact
  end
  
end


