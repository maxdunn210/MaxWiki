class MailerSubscriptionsController < ApplicationController

  layout 'main'  
  helper :sort
  include SortHelper
  before_filter :authorize_admin  
  
  def index
    list
    render :action => 'list'
  end

  def list
    sort_init 'subscribed'
    sort_update
    @mailer_subscriptions = MailerSubscription.paginate(:page => params[:page], :per_page => session_get(:items_per_page), 
    :order => sort_clause)
  end

  def new
    @mailer_subscription = MailerSubscription.new
  end

  def create
    @mailer_subscription = MailerSubscription.new(params[:mailer_subscription])
    if @mailer_subscription.save
      flash[:notice] = 'MailerSubscription was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @mailer_subscription = MailerSubscription.find(params[:id])
  end

  def update
    @mailer_subscription = MailerSubscription.find(params[:id])
    if @mailer_subscription.update_attributes(params[:mailer_subscription])
      flash[:notice] = 'MailerSubscription was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    name = "Record ##{params[:id]}"
    begin
      mailer_subscription = MailerSubscription.find(params[:id])      
      name = "#{mailer_subscription.id}"
      mailer_subscription.destroy
      flash[:notice] = "MailerSubscription '#{name}' was successfully deleted."
    rescue
      flash[:notice] = "Error deleting MailerSubscription '#{name}'."
    end
    redirect_to :action => 'list'
  end

end
