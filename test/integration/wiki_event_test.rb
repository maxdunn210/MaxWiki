require File.dirname(__FILE__) + '/../test_helper'

# These tests are for event schedules on Wiki pages. Events have already
# been tested, so this just makes sure that the buttons work and come
# back to the wiki page
class WikiEventTest < ActionController::IntegrationTest
  fixtures :events, :teams, :lookups, :wikis, :system, :revisions, :pages, :wiki_references, :adults

  def test_page
    get url_for(:controller => 'wiki', :action => 'show', :link => 'majors_schedule')
    verify_status_ok 
  end
  
  def test_schedule
    login_admin_integrated
    update_test_page("<%= schedule %>")
    assert_events(:opening_day, :giants_game, :giants_practice, :marlins_game, :as_game)
  end

  def test_schedule_majors
    login_admin_integrated

    update_test_page("<%= schedule :level => 'Majors' %>")    
    assert_events(:opening_day, :giants_game, :giants_practice, :marlins_game)
    assert_no_events(:as_game)
  end
  
  def test_schedule_majors_giants
    login_admin_integrated

    update_test_page("<%= schedule :level => 'Majors', :team => 'Giants' %>")
    assert_events(:opening_day, :giants_game, :giants_practice)
    assert_no_events(:marlins_game, :as_game)
  end
  
  def test_game_schedule
    login_admin_integrated

    update_test_page("<%= game_schedule %>")
    assert_events(:giants_game, :as_game, :marlins_game)
    assert_no_events(:opening_day, :giants_practice)
  end
  
  def test_game_schedule_majors
    login_admin_integrated

    update_test_page("<%= game_schedule :level => 'Majors' %>")    
    assert_events(:giants_game, :marlins_game)
    assert_no_events(:opening_day, :as_game, :giants_practice)
  end
  
  def test_game_schedule_majors_giants
    login_admin_integrated

    update_test_page("<%= game_schedule :level => 'Majors', :team => 'Giants' %>")    
    assert_events(:giants_game)
    assert_no_events(:opening_day, :marlins_game, :as_game, :giants_practice)
  end
  
  def test_practice_schedule_majors_giants
    login_admin_integrated

    update_test_page("<%= practice_schedule :level => 'Majors', :team => 'Giants' %>")    
    assert_events(:giants_practice)
    assert_no_events(:opening_day, :giants_game, :marlins_game, :as_game)
  end
  
  def test_game_and_practice_schedule_majors_giants
    login_admin_integrated

    update_test_page("<%= game_and_practice_schedule :level => 'Majors', :team => 'Giants' %>")    
    assert_events(:giants_game, :giants_practice)
    assert_no_events(:opening_day, :marlins_game, :as_game)
  end
  
  def test_return
    login_admin_integrated

    # When editing then submit or cancel from wiki page, go back to wiki page
    update_test_page("<%= schedule :level => 'Majors' %>")    
    verify_status_ok 
    
    get url_for(:controller => 'events', :action => 'edit', :id => events(:giants_game).id)
    verify_status_ok 
    post url_for(:controller => 'events', :action => 'update', :id => events(:giants_game).id)
    assert_redirected_to url_for(:controller => 'wiki', :action => 'show', :link => 'test')

    get url_for(:controller => 'events', :action => 'edit', :id => events(:giants_game).id)
    verify_status_ok 
    verify_return('Cancel', 'wiki', 'show', 'test')

    # When same done on events page, go back to event page
    get url_for(:controller => 'events', :action => 'list')
    verify_status_ok 
  
    get url_for(:controller => 'events', :action => 'edit', :id => events(:giants_game).id)
    verify_status_ok 
    post url_for(:controller => 'events', :action => 'update', :id => events(:giants_game).id)
    assert_redirected_to url_for(:controller => 'events', :action => 'list')

    get url_for(:controller => 'events', :action => 'edit', :id => events(:giants_game).id)
    verify_status_ok 
    verify_return('Cancel', 'events', 'list')

  end
  
 #--- Private event helper methods ---  
private
  def assert_events(*syms)
    for sym in syms
      assert_tag(:tag => 'td', :child => { :tag => 'a', 
        :attributes => { :href => "/_action/events/edit/#{events(sym).id}"}})
    end    
  end

  def assert_no_events(*syms)
    for sym in syms
      assert_no_tag(:tag => 'td', :child => { :tag => 'a', 
        :attributes => { :href => "/_action/events/edit/#{events(sym).id}"}})
    end    
  end

  def verify_status_ok
    assert_equal 200, status, 
    :message => "\nRedirected to #{response.redirected_to.inspect}\nFlash=#{flash[:error]}"
  end
    
end
