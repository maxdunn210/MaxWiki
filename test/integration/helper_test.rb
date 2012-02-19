require File.dirname(__FILE__) + '/../test_helper'

class HelperTest < ActionController::IntegrationTest
  fixtures :events, :teams, :players, :adults, :doctors, :lookups, :wikis, :system, :revisions, :pages, :wiki_references
  
  def test_player_list
    login_admin_integrated
    update_test_page("<h3>Num=<%= players_size %></h3>\n\n<h4><%= player_list %></h4>")
    assert_tag(:tag => 'h3', :content => 'Num=4')
    assert_tag(:tag => 'h4', :content => 'Joey, Max, Max, and Maxie')

    update_test_page("<h4><%= player_list(:fee_paid) %></h4>")
    assert_tag(:tag => 'h4', :content => 'Max and Maxie')
  end
end
