require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../mocks/test/email_test'
require 'register_controller'

# Re-raise errors caught by the controller.
class RegisterController; def rescue_action(e) raise e end; end

class RegisterControllerTest < Test::Unit::TestCase
  fixtures :adults, :players, :households, :doctors, :wikis, :system, :surveys, :survey_questions, :survey_answers, :survey_responses
  
  def setup
    @controller = RegisterController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end
  
  def test_index
    get :index
    assert_no_errors
    assert_redirected_to :action => 'setup'
    
    test_create
    get :index
    assert_no_errors
    assert_redirected_to :action => 'list'
  end
  
  def test_new
    login_helper('User')
    get :new
    assert_no_errors
    assert_response :success
    assert_template 'new'
  end
  
  def test_create
    login_helper('User', 1008)
    setup_params
    setup_attribs
    
    ActionMailer::Base.deliveries = []
    post :create, @post_params
    assert_no_errors
    assert_redirected_to :action => 'index'
    assert_read
    assert_equal 1, ActionMailer::Base.deliveries.size
    
    mail = ActionMailer::Base.deliveries[0]
    assert_equal 'adult1@email.com', mail.to_addrs[0].to_s
    assert_match(/Dear Daddy Adult2/, mail.encoded)
    assert_match(/http:\/\/#{@request.host}\/_action\/register/, mail.encoded)
  end
  
  def test_outside_boundaries
    login_helper('User')
    setup_params
    setup_attribs
    @post_params['household'] = {"city"=>"San Jose", "zip"=>"95129", "address"=>"1488 Pine Grove Way"}
    post :create, @post_params
    assert_equal('Your address is not in the boundaries of this league. Please contact info@tricitiesbaseball.org to see if you are eligible for a waiver to play in this league.', flash[:error])
  end
  
  def test_update
    test_create
    
    @post_params['id'] = @player.id
    @player_params['firstname'] = 'New Claire'
    @household_params['city'] = 'New Pine Grove Way'
    @adult1_params['lastname'] = 'New Adult1'
    @adult2_params['lastname'] = 'New Adult2'
    @emer_contact_params['lastname'] = 'New Emergency Contact'
    @doctor_params['physician_name'] = 'New Doctor'
    setup_attribs
    
    post :update, @post_params
    assert_no_errors
    assert_redirected_to :action => 'index'
    assert_read
  end
  
  def test_show
    get :show, :id => 1004
    assert_response :redirect
    assert_equal("Please log in", flash[:notice])
    assert_redirected_to :action => 'login'
    
    login_helper('User')
    get :show, :id => 1007
    assert_redirected_to :action => 'list'
    assert_equal("You are not authorized to access that player", flash[:notice])
    
    get :show, :id => 1006
    assert_response :success
    assert_template 'show'
    assert_tag(:tag => 'h2', :content => /^Maxie Dunn/ )
    
    login_admin
    get :show, :id => 1006
    assert_response :success
    assert_template 'show'
    assert_tag(:tag => 'h2', :content => /^Maxie Dunn/ )
  end
  
  def test_info_checked
    login_helper('User')
    
    get :index
    assert_redirected_to :action => 'list'
    follow_redirect
    assert_show_player(1005)
    
	get :volunteer
	assert_show_player_from_volunteer(1005)
	
	get :pay
    assert_show_player_from_pay(1005)
	
    confirm_player(1005)
    
    assert_show_player(1006)
    confirm_player(1006)
    assert_equal({}, flash)
    
    get :pay
    assert_template 'pay'
    assert_no_errors
    assert_tag(:tag => 'td', :content => 'Jamie Birthday Before')
    assert_tag(:tag => 'td', :content => 'Maxie Dunn')
    assert_tag(:tag => 'td', :content => 'Claire Dunn')
  end
  
  def test_pay
    login_helper('User')
    
    get :pay
    follow_redirect
    assert_msg_error('Please confirm information for all players before moving forward to pay.')
	
	player_1004 = Player.find(1004)
    player_1005 = Player.find(1005)
    player_1006 = Player.find(1006)
    player_1005.info_checked = true
    player_1005.save!
    player_1006.info_checked = true
    player_1006.save!
	
    # player_1004 league age 9-12
    # player_1005 league age 9-12
    # player_1006 league age 13-17
	get :pay
    assert_no_errors
    assert_totals('$300.00', '$140.00')
    
    player_1005.fee_paid = 140.0
    player_1005.save!
    player_1006.fee_paid = 160.0
    player_1006.save!

    # No snack shack deposit or volunteer fees Nov. 2010
    get :pay
    assert_no_errors
    assert_totals('$0.00', '$440.00')
	
	user = User.find_by_household_id(1006)
	survey = Survey.find_by_name('Volunteer')
    existing_response = survey.find_response(user, nil)
	question = existing_response.find_answer_by_question_name("Who")
	question.answer = "None (+$75.00)"
	question.save!
    player_1005.fee_paid = 140.0
    player_1005.save!
    player_1006.fee_paid = 160.0
    player_1006.save!
	
    get :pay
    assert_no_errors
    assert_totals('$0.00', '$440.00')	
  end

  def test_roster
    get :roster, :team => 'Giants'
    assert_no_errors
    assert_template 'player_list'
    tags = find_all_tag(:tag => 'li', :ancestor => {:tag => 'div', :attributes => {:id => "middle_column"}})
    assert_equal(2, tags.size)
    assert_equal('Max D.', tags[0].children.to_s)
    assert_equal('Max T.', tags[1].children.to_s)
  end
  
  def test_volunteer_survey
    get :volunteer
	assert_redirected_to :action => 'login'
	
    login_helper('User')
	
    player_1005 = Player.find(1005)
    player_1006 = Player.find(1006)
    player_1005.info_checked = false
    player_1005.save!
    player_1006.info_checked = false
    player_1006.save!
    
	get :volunteer
    follow_redirect
    assert_msg_error('Please confirm information for all players before moving forward to volunteer job selection.')

    player_1005 = Player.find(1005)
    player_1006 = Player.find(1006)
    player_1005.info_checked = true
    player_1005.save!
    player_1006.info_checked = true
    player_1006.save!

    get :volunteer
	assert_no_errors
  end
  
  #---------------------
  private  
  
  def assert_middle_column(content)
    assert_tag(:tag => 'div', :attributes => {:id => "middle_column"}, :content => content)
  end
  
  def assert_show_player(player_id)
    assert_redirected_to :action => 'show', :id => player_id
    follow_redirect
    assert_tag(:tag => 'div', :attributes => { :class => "msg_notice"}, 
    :content => 'Please confirm this information.')
  end  
  
  def assert_show_player_from_volunteer(player_id)
    assert_redirected_to :action => 'show', :id => player_id
    follow_redirect
    assert_msg_error('Please confirm information for all players before moving forward to volunteer job selection.')
  end  
  
  def assert_show_player_from_pay(player_id)
    assert_redirected_to :action => 'show', :id => player_id
    follow_redirect
    assert_msg_error('Please confirm information for all players before moving forward to pay.')
  end  
  
  def assert_totals(total_fee, fees_paid)  
    assert_tag(:tag => 'td', :attributes => {:id => "total_fee"}, :content => total_fee)
    assert_tag(:tag => 'td', :attributes => {:id => "fees_paid"}, :content => fees_paid)
  end   

  def confirm_player(player_id)
    post :confirm_player_info, :id => player_id
    assert_redirected_to :action => 'list'
    follow_redirect
  end  
  
  def setup_params
    @test_lastname = "Test Unique Name"
    @player_params = {"lastname"=>@test_lastname, "firstname"=>"Claire", "grade"=>"2nd", "lastlevel"=>"T-Ball", 
        "shirtsize"=>"Youth Small", "pantsize"=>"Youth Small", 
        "teacher"=>"Mrs. Ma", "note"=>"", "allergies"=>"", "limitation"=>"No", "years_exp"=>"1", "school"=>"Meyerholz",
        "birthday(1i)"=>"1988", "birthday(2i)"=>"9", "birthday(3i)"=>"25", "info_checked"=>true}
    @household_params = {"city"=>"Cupertino", "zip"=>"95014", "address"=>"10721 Gascoigne Drive"}
    @adult1_params = {"lastname"=>"Adult1", "firstname"=>"Daddy", "work_phone"=>"adult1 work phone", "cell_phone"=>"adult1 cell phone", "home_phone"=>"adult1 home phone","email"=>"adult1@email.com"}
    @adult2_params = {"lastname"=>"Adult2", "firstname"=>"Mommy", "work_phone"=>"adult1 work phone", "cell_phone"=>"adult2 cell phone", "home_phone"=>"adult2 home phone","email"=>"adult2@email.com"}
    @emer_contact_params = {"lastname"=>"Emergency", "firstname"=>"Friend", "work_phone"=>"emergency work phone", "cell_phone"=>"emergency cell phone", "relationship"=>"Friend", "home_phone"=>"emergency home phone", "email"=>"emergency@email.com"}
    @doctor_params = {"physician_name"=>"Dr. Babcock", "physician_addr"=>"100 Doctor Road", "policy_num"=>"54bc65", "healthplan"=>"Blue Shield", "physician_tel"=>"Doctor phone"}
    @post_params = {
      "player" => @player_params,
      "household" => @household_params,
      "adult1" => @adult1_params,
      "adult2" => @adult2_params, 
      "emer_contact" => @emer_contact_params, 
      "doctor" => @doctor_params
    }
  end
  
  def setup_attribs
    # Adjust for what will be read back from the database
    @player_attrib = @player_params.dup
    @player_attrib.delete_if {|key, value| key =~ /birthday\(.*/ }
    @player_attrib['years_exp'] = 1
    @household_attrib = @household_params.dup
    @adult1_attrib = @adult1_params.dup
    @adult2_attrib = @adult2_params.dup
    @emer_contact_attrib = @emer_contact_params.dup
    @doctor_attrib = @doctor_params.dup
  end
  
  def assert_read
    @player = Player.find(:first, :conditions => ['lastname = ?', @test_lastname])
    
    assert_attributes("player", @player.attributes, @player_attrib)
    assert_attributes("household", @player.household.attributes, @household_attrib)
    assert_attributes("adult1", @player.household.adult1.attributes, @adult1_attrib)
    assert_attributes("adult2", @player.household.adult2.attributes, @adult2_attrib)
    assert_attributes("emer_contact", @player.household.emer_contact.attributes, @emer_contact_attrib)
    assert_attributes("doctor", @player.household.doctor.attributes, @doctor_attrib)
  end
  
  def assert_attributes(name, attrib_read, attrib_saved)
    arr_read = attrib_read.sort
    arr_saved = attrib_saved.sort
    arr_diff = arr_saved - arr_read
    
    msg = ''    
    msg << "Error in '#{name}'" if name
    arr_diff.each do |elem|
      msg << ", '#{elem[0]}' Saved=#{attrib_saved[elem[0]]} Read=#{attrib_read[elem[0]]}"
    end  
    
    # We don't care if there are more items that were read back than what we saved
    assert((arr_saved - arr_read).empty?, msg)
  end
  
end
