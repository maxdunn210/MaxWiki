require 'boolean_generator'
require 'csv'

class EventsController < ApplicationController
  
  include SortHelper
  include EventsHelper
  helper :date_picker
  helper :sort
  layout 'main'  
  before_filter :authorize_editor, :only => [:new, :create, :edit, :update, :destroy]
  before_filter :authorize_admin, :only => [:import]
  attr_accessor :last_level
  
  def index
    list
  end
  
  def list
    save_url(:last_event_list_url)
    
    # Defaults if no params
    conditions = ''
    action = "list"
    layout = true
    
    # Instance variables used in the views
    @kinds = [Event::GAME, Event::PRACTICE, Event::EVENT] 
    @head = ''
    @show_level = true
    
    unless params.nil?
      
      @kinds = params[:kind] if params[:kind]
      
      unless session_get(:show_past)
        if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
          date_condition = "AGE(date_time) <= interval '0 days'" 
        else
          date_condition = "TO_DAYS(date_time) >= TO_DAYS(NOW())" 
        end
        
      end  
      
      if params[:kind]        
        kind_list = params[:kind].inspect.delete('[]').gsub('"',"'")
        kind_condition = "events.kind in (#{kind_list})" 
      end
      
      @show_level = false if params[:level]
      
      if params[:level] and !params[:team]  
        level_condition = "home_team_level.name = '#{params[:level]}'" 
      end  
      
      # Look for team in both home and visitor fields. 
      if params[:team]
        @team = Team.find_team(params)
        team_condition = @team ? "(home_team.id = '#{@team.id}' or visitor_team.id = '#{@team.id}')" : nil
      end  
      
      # If we are showing events, show them regardless of the team or level
      if @kinds.include?(Event::EVENT) and (params[:team] or params[:level])
        event_condition = "events.kind = '#{Event::EVENT}'" 
      end
      
      bool = BooleanGenerator.new
      bool.add(date_condition, 'and')
      bool.add(kind_condition, 'and')
      bool.paren_open
      bool.add(event_condition, 'or')
      bool.paren_open
      bool.add(team_condition, 'and')
      bool.add(level_condition)
      bool.paren_close
      bool.paren_close
      conditions = bool.to_s
      
      action = case params[:kind]
      when Event::EVENT then "list_events"
      when Event::GAME then "list_games"
      when Event::PRACTICE then "list_practices"
      else "list"
      end
      
      layout = !params[:no_layout]
    end      
    conditions = 'true' if conditions.empty?
    
    # Setup the header based on what kinds of events we are showing
    if layout
      @kinds.each {|kind| @head << kind + '-'}
      @head.gsub!(/-$/,'')
      @head << " Schedule"
    else
      @suppress_head = true
    end
    
    sort_init 'date_time'
    sort_update
    @events = Event.paginate(:page => params[:page], :per_page => session_get(:items_per_page), 
    :order => sort_clause, :conditions => conditions,
    :include => [{:home_team => [:level, :league]}, {:visitor_team => [:level, :league]}, :location])
    
    render :action => action, :layout => layout
  end
  
  def new
    @event = Event.new
    @event.date_time = session[:event_last_date_time] || Time.now
    @event.kind = params[:kind] || Event::EVENT
    @last_level = saved_level
  end
  
  def create
    @event = Event.new(params[:event])
    @event.date_time = add_time(@event.date_time)
    session[:event_last_date_time] = @event.date_time
    @event.check_and_assign_name(params)
    @last_level = @event.home_team.level_id rescue saved_level # in case there is an error saving
    if !check_conflicts(@event) and @event.save
      flash[:notice] = 'Event was successfully created.'
      redirect_to_last_list
    else
      render :action => 'new'
    end
  end
  
  def edit
    @event = Event.find(params[:id])
    @last_level = @event.home_team.level_id rescue saved_level
  end
  
  def update
    @event = Event.find(params[:id])
    @event.attributes = params[:event]
    @event.date_time = add_time(@event.date_time)
    @event.check_and_assign_name(params)
    @last_level = @event.home_team.level_id rescue saved_level # in case there is an error saving
    if !check_conflicts(@event) and @event.save
      flash[:notice] = 'Event was successfully updated.'
      redirect_to_last_list
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    name = "Record ##{params[:id]}"
    begin
      record = Event.find(params[:id])   
      name = record.send(Event.content_columns[0].name)      
      record.destroy
      flash[:notice] = "Event '#{name}' was successfully deleted."
    rescue
      flash[:notice] = "Error deleting Event '#{name}'."
    end
    redirect_to_last_list
  end
  
  def import
    if request.method == :get
      return
    end
    @import_list = params[:import_list]
    
    csv = CSV::parse(@import_list)
    if csv[0] != ["Field", "Date", "Day", "Time", "Duration", "Team1", "Team2", "Notes"]
      flash.now[:error] = "First line needs to be 'Field, Date, Day, Time, Duration, Team1, Team2, Notes'"
      return
    end
    csv.delete_at(0)
    
    locations = {}
    Lookup.find_all(Lookup::LOCATION).each do |l| 
      locations[l.name.downcase] = l.id unless l.name.blank?
      locations[l.short_name.downcase] = l.id unless l.short_name.blank?
    end  
    
    teams = {}
    Team.find(:all, :include => [:league, :level]).each do |t|
      teams["#{t.league.short_name}:#{t.level.name}:#{t.name}".downcase] = t.id
    end
    
    events = []
    bad_locations = []
    bad_teams = []
    year = Time.now.year
    csv.each do |c|
      bad_flag = false
      
      location_name = c[0]
      location_id = locations[location_name.downcase]
      if location_id.nil?
        bad_flag = true
        bad_locations << location_name unless bad_locations.include?(location_name)
      end
      
      date_time = Time.parse("#{c[1]} #{c[3]}")
      duration = c[4]
      
      home_team_name = c[5]
      home_team_id = teams[home_team_name.downcase]
      if home_team_id.nil?
        bad_flag = true
        bad_teams << home_team_name unless bad_teams.include?(home_team_name)
      end
      
      visitor_team_name = c[6]
      if visitor_team_name.blank?
        kind = Event::PRACTICE
      else
        kind = Event::GAME
        visitor_team_id = teams[visitor_team_name.downcase]
        if visitor_team_id.nil?
          bad_flag = true
          bad_teams << visitor_team_name unless bad_teams.include?(visitor_team_name)
        end
      end
      note = c[7]
      
      unless bad_flag
        events << Event.new(:kind => kind, :name => kind, :date_time => date_time, :length => duration, 
                            :home_team_id => home_team_id, :visitor_team_id => visitor_team_id, 
                            :location_id => location_id, :note => note)
      end
    end  
    
    number_saved = 0
    if bad_locations.blank? && bad_teams.blank?
      flash.now[:error] = ''
      events.each do |e| 
        conflicts = check_conflicts(e)
        if conflicts
          flash.now[:error] << "#{e.date_time.to_date} #{e.location.short_name}: #{e.name} at " +
            "#{format_event_time_and_duration(e.date_time, e.length, :no_break => true)} #{e.errors.entries[0][1]}\n"
        else
          number_saved += 1
          e.save!
        end
      end  
      flash.now[:error] = nil if flash.now[:error].blank?
      flash.now[:notice] = "#{number_saved} events saved"
    else
      flash.now[:error] = ''
      flash.now[:error] << "Bad teams: #{bad_teams.to_sentence}" unless bad_teams.blank?
      flash.now[:error] << "\n\n" unless flash.now[:error].blank?
      flash.now[:error] << "Bad locations: #{bad_locations.to_sentence}" unless bad_locations.blank?
      return
    end
  end
  
  def redirect_to_last_list
    redirect_to_last_url(:last_event_list_url)
  end
  
  def saved_level
    session[:last_level] ||= Lookup.find(:first, 
                                         :conditions => "kind = '#{Lookup::LEVEL}'",
    :order => "display_order, name").id
  end
  
  def saved_level=(val)
    val = val.to_i
    session[:last_level] = val
  end
  
  # Ajax call. It will pass the event kind, which needs to be passed
  # back to "teams_select" to know whether to show 1 or 2 teams
  def change_level
    @event = Event.new(params[:event])
    @event.kind = params[:kind]
    @last_level = self.saved_level = request.raw_post.to_i
    render(:partial => 'teams_select', :layout => false)
  end
  
  #--- Don't make this private because it is called from events_controller_test ---
  def add_time(dt)
    hour = params[:time][:hour].to_i rescue 0
  minute = params[:time][:minute].to_i rescue 0
    if hour.between?(0, 23) and minute.between?(0, 59)
      Time.local(dt.year, dt.month, dt.day, hour, minute, 0)
    else
      raise("Bad time. Hour=#{hour}, Minute=#{minute}")
    end  
  end
  
  #-------------------------  
  private
  
  def check_conflicts(event)
    conflicts = false
    conflicting_events = event.check_schedule_conflicts
    unless conflicting_events.nil? or conflicting_events.empty?
      conflicts = true
      
      conflict_s = ''
      conflicting_events.each {|e| conflict_s << "#{e.name} at " +
      "#{format_event_time_and_duration(e.date_time, e.length, :no_break => true)} and "}
      conflict_s.gsub!(/\sand\s$/,'')
      event.errors.add(:date_time, " conflicts with #{conflict_s}.")
    end
    
    conflicts
  end
end
