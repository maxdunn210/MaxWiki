# Schema as of Wed Apr 05 20:13:53 Pacific Daylight Time 2006 (schema version 7)
#
#  id                  :integer(11)   not null
#  name                :string(40)    
#  level_id            :integer(11)   
#  manager             :string(60)    
#  league_id           :integer(11)   
#  page_name           :string(100)   
#

class Team < MaxWikiActiveRecord
  
  belongs_to :wiki
  belongs_to :league, :class_name => "Lookup", :foreign_key => "league_id"
  belongs_to :level, :class_name => "Lookup", :foreign_key => "level_id"
  
  # A collection listing all the teams to use in a pick list
  def self.picklist(options = {})
    
    params = []
    one_level = !Lookup.find(options[:level_id]).name.empty? rescue nil
    if one_level 
      one_level_conditions = "level_id = ?"
      params << options[:level_id]
    end
    
    home_league_only = options[:home_league_only] || false
    if home_league_only
      home_league = Lookup.find(:first, :conditions => {:kind => Lookup::LEAGUE}, :order => 'display_order')
      if home_league
        home_league_conditions = "league_id = ?"
        params << home_league.id
      end
    end
    
    bool = BooleanGenerator.new
    bool.add(one_level_conditions, 'and')
    bool.add(home_league_conditions)
    if params.empty?
      conditions = true
    else
      conditions = [bool.to_s, params].flatten
    end
    
    Team.find(:all, 
              :order => "level.display_order, league.display_order, teams.name", 
    :include => [ :league, :level],
    :conditions => conditions).map {|t| [t.full_name(one_level, home_league_only), t.id]}
  end
  
  # Since there can teams in different levels or leagues with the same name
  # find the first one in sort_order which will be our league
  def self.find_team(params)
    return nil if params[:team].nil?
    
    if params[:level]
      team_find_conditions = ["teams.name = ? and level.name = ?", params[:team], params[:level] ]
    else
      team_find_conditions = ["teams.name = ?", params[:team] ]
    end
    team = Team.find(:first, :conditions => team_find_conditions, 
                     :order => "league.display_order",
    :include => [:league, :level])
  end
  
  def full_name(one_level = false, one_league = false)
    level_name = ((level.nil? || one_level || level.name.blank?) ? '' : "#{level.name} ")
    league_short_name = ((league.nil? || one_league || league.short_name.blank?) ? '' : "#{league.short_name} ")
    "#{level_name}#{league_short_name}#{name}"
  end
  
  def league_and_name
    league_short_name = (league.nil? ? "" : "#{league.short_name}:" )
    league_short_name + name
  end
end
