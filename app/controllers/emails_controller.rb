require "ar_sendmail"

class EmailsController < ApplicationController

  layout 'main'  
  helper :sort
  include SortHelper
  before_filter :authorize_admin  
  
  def index
    list
    render :action => 'list'
  end

  def list
    sort_init 'updated_at'
    sort_update
    @emails = Email.paginate :page => params[:page], :per_page => session_get(:items_per_page), 
      :order => sort_clause, :include => :mailer      
  end

  def new
    @email = Email.new
  end

  def create
    @email = Email.new(params[:email])
    if @email.save
      flash[:notice] = 'Email was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @email = Email.find(params[:id])
  end

  def update
    @email = Email.find(params[:id])
    if @email.update_attributes(params[:email])
      flash[:notice] = 'Email was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    name = "Record ##{params[:id]}"
    begin
      email = Email.find(params[:id])      
      name = "#{email.to}"
      email.destroy
      flash[:notice] = "Email '#{name}' was successfully deleted."
    rescue 
      flash[:notice] = "Error deleting Email '#{name}'."
    end
    redirect_to :action => 'list'
  end
  
  def delete_all
    Email.delete_all
    begin
       flash[:notice] = "All emails successfully deleted."
    rescue 
      flash[:notice] = "Error deleting emails."
    end
    redirect_to :action => 'list'
  end
  
  def send_emails
     ar_mailer = ActionMailer::ARSendmail.new
     @emails = ar_mailer.find_emails
     ar_mailer.deliver(@emails)
  end

end
