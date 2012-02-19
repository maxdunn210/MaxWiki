require 'erbl'
require 'tmail/utils'

class MailersController < ApplicationController
  
  layout 'main'  
  helper :sort
  include SortHelper
  before_filter :authorize_admin  
  
  def index
    list
    render :action => 'list'
  end
  
  def list
    sort_init 'mailers.name'
    sort_update
    @mailers = Mailer.paginate(:page => params[:page], :per_page => session_get(:items_per_page), 
    :order => sort_clause, :include => :mailer_group)
  end
  
  def new
    setup_groups
    @mailer = Mailer.new
  end
  
  def create
    @mailer = Mailer.new(params[:mailer])
    if @mailer.save
      flash[:notice] = 'Mailer was successfully created.'
      redirect_to :action => 'view', :id => @mailer
    else
      render :action => 'new'
    end
  end
  
  def view
    @mailer = Mailer.find(params[:id])
  end
  
  def edit
    setup_groups
    @mailer = Mailer.find(params[:id])
  end
  
  def update
    @mailer = Mailer.find(params[:id])
    if @mailer.update_attributes(params[:mailer])
      flash[:notice] = 'Mailer was successfully updated.'
      redirect_to :action => 'view', :id => @mailer
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    name = "Record ##{params[:id]}"
    begin
      mailer = Mailer.find(params[:id])      
      name = "#{mailer.name}"
      mailer.destroy
      flash[:notice] = "Mailer '#{name}' was successfully deleted."
    rescue
      flash[:notice] = "Error deleting Mailer '#{name}'."
    end
    redirect_to :action => 'list'
  end
  
  def send_test
    @mailer = Mailer.find(params[:id])    
    unless mailer_setup(@mailer)
      redirect_to :action => 'view', :id => params[:id]
      return
    end
    
    create_email(@user, @mailer)
  end
  
  def process_emails
    @mailer = Mailer.find(params[:id])      
    
    unless mailer_setup(@mailer)
      redirect_to :action => 'view', :id => params[:id]
      return
    end
    
    group = @mailer.mailer_group
    filter = ''
    filter << group.user_filter unless group.user_filter.blank?
    filter << ', ' unless filter.empty? || @mailer.additional_filter.blank?
    filter << @mailer.additional_filter unless @mailer.additional_filter.blank?
    
    if filter.empty?
      @users = User.find(:all)
    else   
      # Check if a hash by looking for "=>" and then turn into a hash
      if filter =~ /=>/
        user_filter = eval("{#{filter}}")
      else 
        user_filter = filter
      end  
      # TODO Capture exceptions and show nice error message
      if MY_CONFIG[:tric]
        @users = Adult.find(:all, :conditions => user_filter, :include => {:household => {:players => {:team => [:league, :level]}}})
      else
        @users = User.find(:all, :conditions => user_filter)
      end
    end 
    
    # Filter out any that don't have valid looking email addresses
    @users.delete_if {|user| user.email.blank? || !user.email.include?('@') }
    
    # Filter out duplicate emails
    added_emails = []
    @users.delete_if do |user| 
      present = added_emails.include?(user.email)
      added_emails << user.email unless present
      present
    end 
    
    # Filter out any users that we have already sent the mailing to
    id_list = Email.find(:all, 
                         :conditions =>  ['mailer_id = ?', @mailer.id]).map {|email| email.user_id}
    @users.delete_if {|user| id_list.include?(user.id) }
    
    # Filter out any users that have specifically unsuscribed to this group
    id_list = MailerSubscription.find(:all, 
                                      :conditions =>  ['mailer_group_id = ? and subscribed = ?', group.id, false]).map {|group| group.user_id}
    @users.delete_if {|user| id_list.include?(user.id) }
    
    # Add in any users that have specifically suscribed to this group
    id_list = MailerSubscription.find(:all, 
                                      :conditions =>  ['mailer_group_id = ? and subscribed = ?', group.id, true]).map {|group| group.user_id}
    new_users = [] 
    user_ids = @users.map {|user| user.id}
    id_list.each {|id| new_users << User.find(id) unless user_ids.include?(id)} 
    @users = @users + new_users
    
    @emails = []
    @users.each do |user|
      @emails << create_email(user, @mailer)
    end
  end
  
  #-----------------
  private
  
  # Needed for time2str which produces a correctly formatted email time string
  include TMail::TextUtils
  
  def create_email(user, mailer)
    email = Email.new
    email.mailer_id = mailer.id
    email.user_id = user.id
    email.status = EMAIL_QUEUED
    email.from = @wiki.config[:email_from]
    email.to = user.email
    
    #set @user for rendering content
    save_user = @user
    @user = user
    
    email.mail = <<EOF
Date: #{time2str(Time.now)}
From: #{email.from}
To: #{email.to}
Subject: #{@subject}
Content-Type: text/html; charset=#{UserSystem::CONFIG[:mail_charset]}

#{ActionMailer::Utils.normalize_new_lines(ERbLight.new(@content, safe_cmds, nil).result(binding))}
EOF
    @user = save_user
    email.save!
    email
  end
  
  def mailer_setup(mailer)
    @subject = mailer.subject
    @page_name = mailer.page
    @page = @wiki.read_page(@page_name)
    if @page.nil?
      flash[:error] = "Page '#{@page_name}' not found"
      return false
    end
    @content = @page.display_content
    return true
  end   
  
  def setup_groups
    @group_list = MailerGroup.find(:all).map {|group| [group.name, group.id]}
  end  
  
end
