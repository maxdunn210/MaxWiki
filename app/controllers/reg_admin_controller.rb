class RegAdminController < ApplicationController

  layout 'main'
  helper :sort
  include SortHelper
  before_filter :authorize_admin

  # The default action displays a status page.
  def index
    if MY_CONFIG[:tric]
      @total_players   = Player.count 
      @total_players_checked   = Player.count(:conditions => ['info_checked = ?', true])
      @total_players_paid   = Player.count(:conditions => ['fee_paid > ?', 0])
    end  
    @total_users = User.count()
    @total_paid = User.count(:conditions => ['paid = ?', true])
    @total_not_paid = User.count(:conditions => ['paid = ? and wait_list_pos = ?', false, 0])
    @total_waiting_list = User.count(:conditions => ['wait_list_pos > ?', 0])
  end 

  def list_players
    save_url(:last_player_list_url)
    
    condition = ['info_checked = ?', true] if session_get(:show_checked_only)
    sort_init 'lastname'
    sort_update
    @players = Player.paginate(
      :include => [{:team => :level}],
      :conditions => condition,
      :page => params[:page],
      :per_page => session_get(:items_per_page), 
      :order => sort_clause)  
  end 
  
  def list_users
    sort_init 'lastname'
    sort_update
    @users = User.paginate :page => params[:page], :per_page => session_get(:items_per_page), 
      :order => sort_clause
  end 
  
  def edit_user
    @user = User.find(params[:id])

    if !request.get?
      params[:user].delete('form')
      if @user.update_attributes(params[:user])
        flash[:notice] = "User #{@user.full_name} updated"
        redirect_to(:action => 'list_users')
      else
        flash.now[:notice] = "There was an error updating the user."
      end
    end
  end
  
  # Add a new user to the database.
  def new_user
    if request.get?
      @user = User.new
    else
      @user = User.new(params[:user])
      if @user.save
        flash[:notice] = "User #{@user.full_name} created"
        redirect_to(:action => 'list_users')
      else
        flash.now[:notice] = "There was an error creating the user."
      end
    end
  end

  # Delete the user with the given ID from the database.
  def delete_user
    id = params[:id]
    if id && user = User.find(id)
      begin
        user.destroy
        flash[:notice] = "User #{user.full_name} deleted"
      rescue
        flash[:notice] = "Can't delete that user"
      end
    end
    redirect_to(:action => :list_users)
  end
  
  def export_players
    @players = Player.find(:all)
    #~ sort_init 'lastname'
    #~ sort_update
    #~ @players = Player.find( :order => sort_clause)
    render :action => 'export_players', :layout => false
  end
  
  def export_users
    @users = User.find(:all)
    render :action => 'export_users', :layout => false
  end
  
  def svn_update
    @svn_username = cookies['svn_username']
    @svn_password = cookies['svn_password']
  end
  
  def do_svn_update
    # Set the umask so the files created will be world readable
    # Otherwise they will only be r/w by owner and so the http server won't see them
    # This is likely caused by setting the umask on suexec so that cgi programs won't be able
    # to write world readable files by default
    # (Note that svn from the command line produces files based on the current umask, which is
    #  usually 0022 so the files are 644)
    #File.umask(0022)

    @svn_username = params[:reg_admin][:svn_username]
    @svn_password = params[:reg_admin][:svn_password]
    cookies['svn_username'] = { :value => @svn_username, :expires => Time.now }
    cookies['svn_password'] = { :value => @svn_password, :expires => Time.now }

    @update_cmd = "svn update #{RAILS_ROOT} --username #{@svn_username} --password #{@svn_password} --non-interactive && sh #{RAILS_ROOT}/../../bin/recycle_fcgi"
    # @update_cmd = "svn status -u ../../httpdocs --username #{@svn_username} --password #{@svn_password} --non-interactive"
    # @update_cmd = 'dir'
    @update_output = `#{@update_cmd}`
    
    if $?.nil? 
      @update_error = "Error"
    elsif $?.exitstatus != 0 
      @update_error = "Error #{$?.exitstatus}"
    else
      @update_error = "No error"
    end
  end
  
  def process_new_year
    unless params[:password] == 'bestof10'
      flash.now[:error] = 'Password needed to process a new year'
      return
    end
    
    @players = Player.find(:all)
    
    @players.each do |player|
    
      # First process player information that needs to be cleared
      lastlevel = player.team.level.name rescue nil
      player.lastlevel = lastlevel unless lastlevel.nil?
      player.fee_paid = 0
      player.fee_paid_on = nil
      player.fee_paid_by = nil
      player.referred_by = nil
      player.team_id = nil
      player.age_checked = false
      player.info_checked = false
      player.tryout_required = false
      player.tryout_date = nil
      player.address_checked = false
      player.form_printed = false
      player.signed_form_received = false
      player.remarks = nil

      # Now clear fees and deposits per household     
      household = player.household
      household.volunteer_feepaid = 0 
      household.volunteer_feepaid_on = nil 
      household.volunteer_feepaid_by = nil 
      household.snackshack_deposit = 0
      household.snackshack_depositpaid_on = nil
      household.snackshack_depositpaid_by = nil
      household.snackshack_refund = 0
      household.snackshack_refunded_on = nil
      household.snackshack_refunded_by = nil
      
      # Now save the databases
      player.save!
      household.save!
      
    end
  end

  def orphan_check
    households = Household.find(:all)
    players = Player.find(:all)
    adults = Adult.find(:all)
    doctors = Doctor.find(:all)
    
    households_with_players = []
    players.each {|player| households_with_players << player.household}
    @orphan_households = households - households_with_players

    valid_household_ids = households_with_players.map {|hh| hh.id}
    
    @orphan_players = []
    players.each do |player| 
      unless valid_household_ids.include?(player.household_id)
        @orphan_players << player
      end  
    end  
    
    @orphan_adults = []
    adults.each do |adult| 
      unless valid_household_ids.include?(adult.household_id)
        @orphan_adults << adult
      end  
    end  

    @orphan_doctors = []
    doctors.each do |doctor| 
      unless valid_household_ids.include?(doctor.household_id)
        @orphan_doctors << doctor
      end  
    end  
    
    if params[:password] == 'bestof10'
      flash.now[:error] = 'Deleted orphans'
      @orphan_doctors.each {|doctor| doctor.destroy}
      @orphan_adults.each {|adult| adult.destroy}
      @orphan_players.each {|player| player.destroy}
      @orphan_households.each {|household| household.destroy}
    end
  end  
  
end
