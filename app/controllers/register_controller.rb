require 'geocode.rb'

class RegisterController < ApplicationController
  
  helper :sort
  include SortHelper
  
  layout 'main'
  
  # Make sure that they are not trying to access a record they didn't create
  before_filter :authorize_user, :except => [:index, :setup, :roster]
  before_filter :check_user, :only => [:edit, :update, :show, :print, :delete_confirm, :destroy, :mark_as_printed_and_print_next]
  before_filter :setup_title
  
  def index
    unless logged_in?
      redirect_to(:action => 'setup')
    else  
      list_setup #Load the list to see if there are any players defined for this user
      if @players.empty?
        # Redirect here because it needs to setup the data first
        redirect_to(:action => 'new')
      else
        # Even if the list is already loaded, redirect to list again so that the breadcrumbs and left menus will know where we are
        redirect_to :action => 'list'
      end
    end  
  end
  
  def list
    save_url(:last_player_list_url)
    
    list_setup
    if @next_player_to_check
      flash[:notice] = 'Please confirm this information.'
      redirect_to :action => 'show', :id => @next_player_to_check.id
    end
  end
  
  def volunteer
    @players = Player.find(:all, :conditions => player_condition,
                           :order => 'id')
    
	@next_player_to_check = @players.find {|p| !p.info_checked}    
    if @next_player_to_check
      flash[:error] = 'Please confirm information for all players before moving forward to volunteer job selection.'
      redirect_to :action => 'show', :id => @next_player_to_check.id
    end

    @adult1 = @players.first.household.adult1
    @adult2 = @players.first.household.adult2

  end
  
  def volunteer_confirm
    survey = Survey.find(:first, :conditions => ['name = ?', "volunteer"])
    if survey.nil?
      return  "Survey '#{name}' not found"
    end
    @existing_response = survey.find_response(@user, nil)
	@questions =  survey.survey_questions.map {|q| q.name}
  end
  
  def roster
    @team = Team.find_team(params)
    if @team.nil?
      @players = nil
    else   
      conditions = "team_id = '#{@team.id}'"
      @players = Player.find(:all,
                             :conditions => conditions, 
                             :order => 'firstname, lastname')
    end                           
    render :action => 'player_list', :layout => !params[:no_layout]
  end
  
  def pay
    household = nil
    @players = Player.find(:all, :conditions => player_condition,
                           :order => 'id')
    
	@next_player_to_check = @players.find {|p| !p.info_checked}    
    if @next_player_to_check
      flash[:error] = 'Please confirm information for all players before moving forward to pay.'
      redirect_to :action => 'show', :id => @next_player_to_check.id
	  return
    end
	
	survey = Survey.find_by_name('Volunteer')
    existing_response = survey.find_response(@user, nil)
    if existing_response.nil?
      flash[:error] = 'Please select volunteer job(s) before paying.'
      redirect_to :action => 'volunteer'
	  return
    end
	
    Player.calc_all_fees(@players)
	
    @volunteer_fee = 0
    # Need to change the options in the Vlunteer survey to not show the "None (+$60.00)" answer. Nov. 2010
	if existing_response.find_answer_by_question_name("Who").answer == "None (+$60.00)"
      @volunteer_fee = 60
	end

	if existing_response.find_answer_by_question_name("Positions").answer == "None (+$60.00)"
      @volunteer_fee = 60
	end
	  
    # Bypass volunteer fee logic by reinitializing the volunteer_fee to 0. Nov. 2010
    # A global $60.00 deposit is going to be collected during walk-in registration 
    @volunteer_fee = 0
    
    # Deposit fee for snack shack used to be 40
    # @deposit_fee = 40
    @deposit_fee = 0
	@earlybird_discount = 0
    @sibling_discount = 0
    @late_fee = 0
    @total_fee = 0 + @volunteer_fee + @deposit_fee
    @fees_paid = 0   
    @players.each do |player| 
      if player.fee_paid == 0 
        @earlybird_discount += player.earlybird_discount
        @sibling_discount += player.sibling_discount
        @late_fee += player.late_fee
        @total_fee += player.net_fee
      else
        @fees_paid += player.fee_paid
      end
	  
      household = player.household
    end
	
	household.volunteer_feepaid = @volunteer_fee
	household.snackshack_deposit = @deposit_fee
	household.save!
  end
  
  def pay_later
    pay
  end
  
  def show
    setup_all(params[:id])
    @screen = true
    @squish = false
    @show_admin_info = true
  end
  
  def confirm_player_info
    setup_all(params[:id])
    @player.info_checked = true
    @player.save!
    redirect_to :action => 'list'
  end
  
  def print
    setup_all(params[:id])
    @screen = false
    @squish = false
    @show_admin_info = true
    render :action => 'show', :layout => 'layouts/simple'
  end
  
  def mark_as_printed_and_print_next
    player = Player.find(:first, :conditions => {:id => params[:id]})
    if !player.nil?
      player.form_printed = true
      player.save!
    end
    
    player = Player.find(:first, :conditions => {:form_printed => false, :info_checked => true}, :order => 'lastname')
    params[:id] = player.id
    print
  end
  
  def new
    setup_all
  end
  
  def edit
    setup_all(params[:id])
  end
  
  def create
    save_all
  end
  
  def update
    save_all(params[:id])
  end
  
  def document
  end
  
  def setup
  end
  
  def delete_confirm
    @player = Player.find(params[:id])
  end
  
  def destroy
    Player.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
  
  def redirect_to_last_player_list
    redirect_to_last_url(:last_player_list_url)
  end
  
  #=================================================================
  private
  #=================================================================
  
  def list_setup(items_per_page = nil, condition = nil)
    items_per_page ||= session_get(:items_per_page)
    condition ||= player_condition 
    sort_init 'lastname'
    sort_update
    @players = Player.paginate(:page => params[:page], :per_page => items_per_page, 
    :include => [{:team => :level}],
    :conditions => condition, 
    :order => sort_clause)
    @next_player_to_check = @players.find {|p| !p.info_checked}  
  end
  
  # If player_id specified, try to find the player and then the ActiveRecord relations will link the household, adult and doctor records.
  # if no player_id, try to find a household corresponding to this user and then link the player to it 
  # However, if in admin mode, then just create new objects for everything
  # Then check each object individually and create a new one if necessary
  def setup_all(player_id = NIL)
    
    adult1 = nil
    household = nil
    if player_id
      # If for some reason the player_id is bad and @player is not found, an exception will be thrown below. That is okay
      # because it should only happen if there is a programming error or a hacking attempt
      @player = Player.find(player_id)
    else
      @player = Player.new
      
      unless Role.check_role(ROLE_ADMIN)
        adult1 = Adult.find(@user.id) rescue nil
      household = Household.find(@user.household_id) rescue nil
      end
    end
    
    # This block is needed for new players. However, also check existing players in case one
    # of the adults or doctor was deleted. Otherwise it will throw exceptions.
    household ||= Household.new
    adult1 ||= Adult.new
    
    @player.household ||= household
    @player.household.doctor ||= Doctor.new
    @player.household.adult1 ||= adult1
    @player.household.adult2 ||= Adult.new
    @player.household.emer_contact ||= Adult.new
    
    @player.household.adult1.adultnum = 1
    @player.household.adult2.adultnum = 2
    @player.household.emer_contact.adultnum = 3
    
    # The "text_field" form command, and possibly others, don't like complicated instance variables, 
    # for example, @player.household. So create simple instance variables to use for forms
    @household = @player.household
    @doctor = @player.household.doctor
    @adult1 = @player.household.adult1
    @adult2 = @player.household.adult2
    @emer_contact = @player.household.emer_contact
    @team = @player.team
  end
  
  # Save the information entered on the form for household, player, adult and doctor records
  # If this is a new player, player_id will be NIL
  def save_all(player_id = NIL)
    
    begin
      # Get the existing records or create new ones
      setup_all(player_id)
      
      #Update them with the data the user entered
      @player.attributes = params[:player]
      @player.household.attributes = params[:household]
      @player.household.doctor.attributes = params[:doctor]
      @player.household.adult1.attributes = params[:adult1]
      @player.household.adult2.attributes = params[:adult2]
      @player.household.emer_contact.attributes = params[:emer_contact]
      
      # Do the other updates
      # Only update the session_id if it is nil, in case we are editing as admin
      player_update_protected
      begin
        geo = Geocode.new("#{params[:household][:address]}, #{params[:household][:zip]}")
        @player[:waiver_required] = geo.waiver_required
      rescue
        @player[:waiver_required] = true
      end
      @player.household.session_id ||= session.session_id
      
      # MD 9/27/2006 Updating to Rails edge 1.1.6 caused the table related to household to 
      # not be saved. So save them all specifically.
      # Because there can be many players for each household, calling @player.save does not save the household record
      # However, saving @player.household.save also saves the adults, and doctor records, since this is a has_one relation
      Player.transaction do
        @player.save!
        @player.household.save!
        @player.household.doctor.save!
        @player.household.adult1.save!
        @player.household.adult2.save!
        @player.household.emer_contact.save!
      end
      
      # validation errors used to not produce exceptions
      # leave this here in case another change is made to Rails
      raise if errors_not_empty
      
      if player_id
        flash[:notice] = 'Player was successfully updated.'
      else
        flash[:notice] = 'Player was successfully created.'
      end
      
      if @player[:waiver_required] or @player.household[:zip] != '95014'
        flash[:error] = 'Your address is not in the boundaries of this league. Please contact ' +              
        'info@tricitiesbaseball.org to see if you are eligible for a waiver to play in this league.'
      end
      
    rescue StandardError => e
      flash.now[:error] = "Error saving player: #{e}"
      
      # It would be nice to "redirect_to edit" here so that the breadcrumbs show "edit" rather than "update" and the URL
      # would also show "edit"  However, if we do that then all the field error information will be lost.  
      # Also, while we could always go to "edit" here, if we are creating a new player there is no param[:id] yet and so
      # "check_user" will block the subsequent "update"
      if player_id
        render :action => 'edit'
      else
        render :action => 'new'
      end
      
      return
    end
    
    #If player created successfully, now send a confirmation email
    begin
      # Don't send unless a new player and not entered by the admin
      if not(player_id or Role.check_role(ROLE_ADMIN) or @player.household.adult1.email.empty?)
        url = url_for(:controller => 'register')
        deliver_now { RegNotifyPlayer.deliver_signup_player(@player, @player.household, 
                                                            @player.household.adult1,@player.household.adult2,
                                                            @player.household.doctor, @player.household.emer_contact, 
                                                            @wiki.config[:email_from], url, @wiki.config) }
        flash[:notice] << ' and a confirmation email was sent.'
      end
    rescue StandardError => e
      flash[:error] = "There was an error sending the confirmation email: #{e}"
    end
    
    redirect_to_last_player_list
  end
  
  #The following parameters shouldn't be set by the user, so to prevent
  # form injection, they are marked in the player.rb model as attr_protected so
  # they need to be assigned manually and only when the admin does it
  #
  # MD Note Nov 11, 2005: There is some wierd stuff going on with the fee_paid_on field
  # If you use " @player[:fee_paid_on] = params[:player][:fee_paid_on]" then NIL is
  # always assigned. This parameter is actually returned in 3 parts: 'fee_paid_on(i1)', 'fee_paid_on(i2)', 'fee_paid_on(i3)'
  # However, when you do the assignment or updated_attributes, Rails seems to know how to deal with this, but I
  # couldn't figure out how to do this. So as a stopgap, we will just leave the 'fee_paid_on' field unprotected. This
  # is not a big problem since we check the fee_paid to see if they paid
  # Also MySQL uses a default date of "0000-00-00" but RoR considers this to be a NIL date so you have to be careful about using this
  # to prevent NIL exceptions
  def player_update_protected
    if Role.check_role(ROLE_ADMIN) and params[:player]
      @player[:fee_paid] = params[:player][:fee_paid] if params[:player][:fee_paid]
      @player[:age_checked] = params[:player][:age_checked] if params[:player][:age_checked]
      @player[:waiver_required] = params[:player][:waiver_required] if params[:player][:waiver_required]
      @player[:address_checked] = params[:player][:address_checked] if params[:player][:address_checked]
      @player[:signed_form_received] = params[:player][:signed_form_received] if params[:player][:signed_form_received]
    end  
  end
  
  # Show the players corresponding to the household_id of the logged in user. 
  def player_condition(condition1 = nil)
    if logged_in?
      hh_id = @user.household_id
    else
      household = find_household_by_session
      if household.nil?
        hh_id = 0  # don't find any players
      else
        hh_id = household.id
      end
    end
    condition2 =  "household_id = '#{hh_id}'"
    
    condition = [condition1, condition2].compact.join(' and ')	  
    condition = nil if condition.empty?
    return condition
  end
  
  def errors_not_empty
    notempty = @player && !@player.errors.empty? 
    notempty ||= @player.household && !@player.household.errors.empty? 
    notempty ||= @player.household.doctor && !@player.household.doctor.errors.empty? 
    notempty ||= @player.household.adult1 && !@player.household.adult1.errors.empty? 
    notempty ||= @player.household.adult2 && !@player.household.adult2.errors.empty? 
    notempty ||= @player.household.emer_contact && !@player.household.emer_contact.errors.empty? 
    return notempty     
  end
  
  def check_user
    unless Role.check_role(ROLE_ADMIN) ||
     (@user && Player.find(params[:id]).household_id == @user.household_id)
      flash[:notice] = "You are not authorized to access that player"
      redirect_to :action => 'list'
    end
  end 
  
  def setup_title
    @title = controller_name.humanize
    @show_footer = false
    return true
  end
end
