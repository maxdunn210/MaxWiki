class Location < MaxWikiActiveRecord
  has_many :usages
  belongs_to :parent, :class_name => 'Location', :foreign_key => "parent_location_id"
  has_many :children, :class_name => 'Location', :foreign_key => "parent_location_id"
end

def Location.gather(start_name)
  
  @locations = []
  location = Location.find_by_name(start_name)
  if location.nil?
    location = Location.find_by_short_name(start_name)
  end
  
  while location
    location_usage = {}
    location_usage[:name] = location.name

    raw_usage = Usage.find(:all, :conditions => {:location_id => location.id})
    raw_usage.each do |usage|
      location_usage[usage.kind] = usage.value
    end
    @locations << location_usage
    location = location.parent
  end  
  
  @locations
end

def Location.names
  Location.find(:all).map {|loc| loc.name}
end
