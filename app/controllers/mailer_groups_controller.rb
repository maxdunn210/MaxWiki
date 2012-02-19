class MailerGroupsController < ApplicationController

  layout 'main'  
  helper :sort
  include SortHelper
  before_filter :authorize_admin  
  
  def index
    list
    render :action => 'list'
  end

  def list
    sort_init 'name'
    sort_update
    @mailer_groups = MailerGroup.paginate(:page => params[:page], :per_page => session_get(:items_per_page), 
    :order => sort_clause)
  end

  def new
    @mailer_group = MailerGroup.new
  end

  def create
    @mailer_group = MailerGroup.new(params[:mailer_group])
    if @mailer_group.save
      flash[:notice] = 'MailerGroup was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @mailer_group = MailerGroup.find(params[:id])
  end

  def update
    @mailer_group = MailerGroup.find(params[:id])
    if @mailer_group.update_attributes(params[:mailer_group])
      flash[:notice] = 'MailerGroup was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    name = "Record ##{params[:id]}"
    begin
      mailer_group = MailerGroup.find(params[:id])      
      name = "#{mailer_group.name}"
      mailer_group.destroy
      flash[:notice] = "MailerGroup '#{name}' was successfully deleted."
    rescue
      flash[:notice] = "Error deleting MailerGroup '#{name}'."
    end
    redirect_to :action => 'list'
  end

end
