require File.dirname(__FILE__) + '/../test_helper'

# These tests are for event schedules on Wiki pages. Events have already
# been tested, so this just makes sure that the buttons work and come
# back to the wiki page
# This also checks to make sure that the sort headers don't throw an exception
#  which can easily happen if the SQL alias names change
class PaginationSortTest < ActionController::IntegrationTest
  fixtures :events, :teams, :players, :adults, :doctors, :lookups, :wikis, :system, :revisions, :pages, :wiki_references, 
    :surveys, :survey_questions, :survey_responses, :survey_answers

  def test_event_sort
    verify_sort url_for(:controller => 'events', :action => 'list')
  end
      
  def test_event_games_sort
    verify_sort url_for(:controller => 'events', :action => 'list', :kind => 'Game')
  end
      
  def test_player_sort
    login_admin_integrated
    verify_sort url_for(:controller => 'register', :action => 'list')
  end

  def test_admin_player_sort
    login_admin_integrated
    verify_sort url_for(:controller => 'reg_admin', :action => 'list_players')
  end

  def test_team_sort
    login_admin_integrated
    verify_sort url_for(:controller => 'teams', :action => 'list')
  end

  def test_lookup_sort
    login_admin_integrated
    verify_sort url_for(:controller => 'lookups', :action => 'list_lookups')
  end

  def test_user_sort
    login_admin_integrated
    verify_sort url_for(:controller => 'reg_admin', :action => 'list_users')
  end

  def test_survey_sort
    login_admin_integrated
    verify_sort url_for(:controller => 'surveys', :action => 'list')
  end
  
  def test_survey_questions_sort
    login_admin_integrated
    verify_sort url_for(:controller => 'survey_questions', :action => 'list', :survey_id => 1)
  end

  def test_survey_responses_sort
    login_admin_integrated
    verify_sort url_for(:controller => 'survey_responses', :action => 'list', :survey_id => 1)
  end

 #--- Private event helper methods ---  
private
 
  def verify_sort(list_url)
    get list_url 
    
    # Find all the sort references. Will be in the form /events/list?sort_key=note ....
    a_tags = find_all_tag( :tag => 'a')
    hrefs = a_tags.map do |tag|
      if tag.to_s =~ (/href=['"](.*?sort_key.*?)['"]/) 
        $1
      end
    end  
    hrefs.compact!
    assert hrefs.length > 0, :message => ": No sort links found"
    
    hrefs.each { |href| verify_url(href)}
  end
      
  def verify_url(url)
    get url.gsub('&amp;','&') # Fix a bug in Rails 2.1
    assert_response :success, :message => ": problem url => #{url}"
  end

end
