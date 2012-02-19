require File.dirname(__FILE__) + '/../test_helper'
require 'events_controller'
require File.dirname(__FILE__) + '/../../app/helpers/events_helper'

# Re-raise errors caught by the controller.
class EventsController; def rescue_action(e) raise e end; end

class EventsControllerTest < Test::Unit::TestCase
  include EventsHelper
  fixtures :events, :teams, :lookups, :wikis, :system
  
  def setup
    @controller = EventsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end
  
  #--- Tests that don't need login ---
  
  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end
  
  def test_list_events
    get :list
    
    assert_response :success
    assert_template 'list'
    assert_not_nil assigns(:events)
  end
  
  def test_list_games
    get :list, :kind => 'Game'
    
    assert_response :success
    assert_template 'list_games'
    assert_not_nil assigns(:events)
    assert_tag(:tag => 'td', :content => 'Check field status')
  end
  
  def test_list_giants_games
    get :list, :kind => 'Game', :level => 'Majors', :team => 'Giants'
    
    assert_response :success
    assert_template 'list_games'
    assert_not_nil assigns(:events)
    #MD This is not working, the <br> tag messes it up
    assert_tag(:tag => 'td', :content => 'Check field status')
    assert_tag(:tag => 'td', :content => 'Giants arrive at 9:15')
  end
  
  def test_list_marlins_schedule
    get :list, :level => 'Majors', :team => 'Marlins'
    
    assert_response :success
    assert_template 'list'
    assert_not_nil assigns(:events)
    assert_tag(:tag => 'td', :content => 'Marlins arrive at 9:30')
  end
  
  #--- Helper tests ---  
  
  def test_format_duration
    assert_equal "30mins", format_event_duration(30)
    assert_equal "45mins", format_event_duration(45)
    assert_equal "1hr", format_event_duration(60)
    assert_equal "1hr 15mins", format_event_duration(75)
    assert_equal "1.5hrs", format_event_duration(90)
    assert_equal "1hr 45mins", format_event_duration(105)
    assert_equal "2hrs", format_event_duration(120)
    assert_equal "2.5hrs", format_event_duration(150)
    assert_equal "2hrs 40mins", format_event_duration(160)
  end
  
  #--- Other tests ---  
  
  def test_add_date
    time = Time.local(2006, 4, 1, 13, 36, 0)
    
    # Good time
    @controller.params = { :time => {:hour => 10, :minute => 30}}
    new_time = @controller.add_time(time)
    assert_equal Time.local(*ParseDate.parsedate("Sat Apr  1 10:30:00 2006")), new_time
    
    # Add 0 time
    @controller.params = { :time => {:hour => 0, :minute => 0}}
    new_time = @controller.add_time(time)
    assert_equal Time.local(*ParseDate.parsedate("Sat Apr  1 00:00:00 2006")), new_time
    
    # Hour too big
    @controller.params = { :time => {:hour => 24, :minute => 30}}
    begin
      new_time = @controller.add_time(time)
      msg = "No exception"
    rescue
      msg = $!.to_s
    end  
    assert_equal "Bad time. Hour=24, Minute=30", msg
    
    # Minute too big
    @controller.params = { :time => {:hour => 10, :minute => 60}}
    begin
      new_time = @controller.add_time(time)
      msg = "No exception"
    rescue
      msg = $!.to_s
    end  
    assert_equal "Bad time. Hour=10, Minute=60", msg
  end
  
  #--- Tests for rejecting actions that need login ---
  
  def test_new_without_login
    get :new, :kind => Event::GAME
    assert_redirected_to :action => 'login'
  end
  
  def test_create_without_login
    post :create, :event => {}
    assert_redirected_to :action => 'login'
  end
  
  def test_edit_without_login
    get :edit, :id => 1
    assert_redirected_to :action => 'login'
  end
  
  def test_update_without_login
    post :update, {:id => 1, :event => { :kind => Event::GAME}}
    assert_redirected_to :action => 'login'
  end
  
  def test_destroy_without_login
    post :destroy, :id => 1  
    assert_redirected_to :action => 'login'
  end
  
  def test_import_without_login
    login_editor # Need an Admin role to import
    
    get :import
    assert_redirected_to :action => 'login'
    
    post :import, :import_list => 'Field 1, Field 2, Field3'
    assert_redirected_to :action => 'login'
  end
  
  #--- Tests requiring login ---
  
  #--- New tests ----
  
  def test_new_game
    login_admin
    get :new, :kind => Event::GAME
    assert_tag(:tag => 'h1', :content => 'New Game')
    verify_new_page
    verify_game_tags
    verify_return('Cancel','events','index')
  end
  
  def test_new_practice
    login_admin
    get :new, :kind => Event::PRACTICE
    assert_tag(:tag => 'h1', :content => 'New Practice')
    verify_new_page
    verify_practice_tags
    verify_return('Cancel','events','index')
  end
  
  def test_new_event
    login_admin
    get :new, :kind => Event::EVENT
    assert_tag(:tag => 'h1', :content => 'New Event')
    verify_new_page
    verify_event_tags
    verify_return('Cancel','events','index')
  end
  
  #--- Create tests ----
  
  def test_create
    login_admin
    num_events = Event.count
    post :create, :event => {:date_time => "2006/03/22 09:30:00"}, 
    :time => { :hour => "17", :minute => "30"}
    assert_equal num_events + 1, Event.count
    assert_response :redirect
    assert_redirected_to :controller => 'events', :action => 'index'
  end
  
  #--- Edit tests ---
  
  def test_edit_game
    login_admin
    get :edit, :id => 1
    assert_tag(:tag => 'h1', :content => 'Edit Game')
    verify_edit_page
    verify_game_tags
    verify_return('Cancel','events','index')
  end
  
  def test_edit_practice
    login_admin
    get :edit, :id => 2
    assert_tag(:tag => 'h1', :content => 'Edit Practice')
    verify_edit_page
    verify_practice_tags
    verify_return('Cancel','events','index')
  end
  
  def test_edit_event
    login_admin
    get :edit, :id => 3
    assert_tag(:tag => 'h1', :content => 'Edit Event')
    verify_edit_page
    verify_event_tags
    verify_return('Cancel','events','index')
  end
  
  #--- Update tests ---
  
  def test_update
    login_admin
    post :update, {:id => 1, 
      :event => { :kind => Event::GAME},
      :time => { :hour => "15", :minute => "00"}}
    assert_redirected_to :controller => 'events', :action => 'index'
  end
  
  #--- Destroy tests ---
  
  def test_destroy
    login_admin
    assert_not_nil Event.find(1)
    
    post :destroy, :id => 1
    assert_redirected_to :controller => 'events', :action => 'index'
    
    assert_raise(ActiveRecord::RecordNotFound) {
      Event.find(1)
    }
  end
  
  #--- Level setting tests ---
  def test_set_level
    login_admin
    
    # When creating a new event, it should use last_level
    @request.session[:last_level] = 1
    @controller.last_level = 1
    get :new, :kind => Event::GAME
    verify_select("T-Ball")
    
    # When updating an event, it should use home team level  
    @request.session[:last_level] = 1
    @controller.last_level = 1
    get :edit, :id => 1
    verify_select("Majors")
    
    #Make sure if there is a conflict on create, level is still set correctly
    @request.session[:last_level] = 1
    @controller.last_level = 1
    post :create, 
    :event => {:kind => Event::GAME,
      :home_team_id => "1", :date_time => "2016/03/30 09:30:00", 
      :length => "120", :location_id => "10"}, 
    :time => { :hour => "9", :minute => "00"}
    assert_response :success
    verify_select("Majors")
    
    #Make sure if there is a conflict on update, level is still set correctly
    @request.session[:last_level] = 1
    @controller.last_level = 1
    post :update, {:id => 1, 
      :event => { :kind => Event::GAME},
      :time => { :hour => "9", :minute => "00"}}
    assert_response :success
    verify_select("Majors")
  end
  
  def verify_select(text)
    assert_tag(:tag => "option",
    :attributes => { :selected => "selected"},
    :content => text)
  end
  
  #--- Conflict tests ---
  def test_conflict
    login_admin
    @request.session[:last_level] = 1
    post :update, {:controller => 'register', :id => 1, 
      :event => { :kind => Event::GAME},
      :time => { :hour => "9", :minute => "00"}}
    assert_response :success
    assert_template 'edit'
    assert_tag(:tag => 'div', 
    :attributes => { :class => 'msg_error'}, 
    :content => "Date time  conflicts with Game at 8:30AM for 1.5hrs and Game at 9:00AM for 1.5hrs and Practice at 9:30AM for 3hrs.")
  end
  
  def test_no_conflict_zero_length
    login_admin
    post :update, {:id => 1, 
      :event => { :kind => Event::GAME, :length => "0"},
      :time => { :hour => "9", :minute => "00"}}
    
    assert_redirected_to :controller => 'events', :action => 'index'
  end
  
  def test_no_conflict_blank_location
    login_admin
    post :update, {:id => 1, 
      :event => { :kind => Event::GAME, :location_id => "12"},
      :time => { :hour => "9", :minute => "00"}}
    
    assert_redirected_to :controller => 'events', :action => 'index'
  end
  
  #--- Import tests ---
  def test_import
    login_admin
    
    # Check that the form is shown without errors
    get :import
    assert_no_errors
    
    # Check that it requires a specific error line
    post :import, :import_list => "Farm,3/15,Sat,11:15,F1,F2,Opening day"
    assert_msg_error("First line needs to be 'Field, Date, Day, Time, Duration, Team1, Team2, Notes'")
 
    import_setup
    
    import_list = <<EOF 
Field,Date,Day,Time,Duration,Team1,Team2,Notes
Wilson-Farm,3/15,Sat,11:15,60,TC:Farm:F1,TC:Farm:F2,Opening day
Wilson-Minors,3/15,Sat,12:15,120,TC:Minors:Bluejays,TC:Minors:Marlins
Wilson-Majors,3/18,Tue,17:15,120,TC:Majors:Giants,CA:Majors:Yankees
Kennedy,3/26,Wed,17:15,120,CN:Majors:Cardinals,TC:Majors:A's
Wilson-Majors,3/17,Mon,17:00,90,TC:Majors:A's
EOF
    
    post :import, :import_list => import_list
    assert_no_errors
    events = Event.find(:all)
    assert_equal(5, events.size)
    
    # Check for time conflicts
    post :import, :import_list => "Field,Date,Day,Time,Duration,Team1,Team2,Notes\nWilson-Farm,3/15,Sat,11:00,60,TC:Farm:F2"
    assert_msg_error('Practice at 11:00AM for 1hr  conflicts with Game at 11:15AM for 1hr')
  end
  
  
  #--- Private event helper methods ---  
  private
  
  def import_setup     
    Event.delete_all
    Team.delete_all
    Lookup.delete_all
    
    ['Wilson-Farm','Wilson-Minors','Wilson-Majors','Kennedy'].each do |name|
      Lookup.new(:kind => Lookup::LOCATION, :name => name).save!
    end
    
    ['Farm','Minors','Majors'].each do |name|
      Lookup.new(:kind => Lookup::LEVEL, :name => name).save!
    end
    
    [['Tri-Cities','TC'],['Cupertino American','CA'],['Cupertino National','CN']].each do |name_pair|
      Lookup.new(:kind => Lookup::LEAGUE, :name => name_pair[0], :short_name => name_pair[1]).save!
    end
    
    ['TC:Farm:F1','TC:Farm:F2','TC:Minors:Bluejays','TC:Minors:Marlins','TC:Majors:Giants','CA:Majors:Yankees',
    'CN:Majors:Cardinals','TC:Majors:A\'s'].each do |name_combo|
      name_a = name_combo.split(':')
      league_id = Lookup.find(:first, :conditions => {:short_name => name_a[0]}).id
      level_id = Lookup.find(:first, :conditions => {:name => name_a[1]}).id
      name = name_a[2]
      Team.new(:name => name, :level_id => level_id, :league_id => league_id).save!
    end
  end
  
  def verify_new_page
    assert_response :success
    assert_template 'new'
    assert_not_nil assigns(:event)
    assert assigns(:event).valid?
  end
  
  def verify_edit_page
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:event)
    assert assigns(:event).valid?
  end
  
  def verify_game_tags
    verify_common_tags
    assert_tag(:tag => 'h1', :content => 'Game')
    assert_tag(:tag => 'label', :content => 'Home')
    assert_tag(:tag => 'label', :content => 'Visitor')
  end  
  
  def verify_practice_tags
    verify_common_tags
    assert_tag(:tag => 'h1', :content => 'Practice')
    assert_tag(:tag => 'label', :content => 'Team')
    assert_no_tag(:tag => 'label', :content => 'Visitor')
  end  
  
  def verify_event_tags
    verify_common_tags
    assert_tag(:tag => 'h1', :content => 'Event')
    assert_tag(:tag => 'label', :content => 'Name')
    assert_no_tag(:tag => 'label', :content => 'Team')
    assert_no_tag(:tag => 'label', :content => 'Visitor')
  end  
  
  def verify_common_tags
    assert_tag(:tag => 'label', :content => 'Time')
    assert_tag(:tag => 'label', :content => 'Duration')
    assert_tag(:tag => 'label', :content => 'Location')
    assert_tag(:tag => 'label', :content => 'Note')
  end  
  
end
