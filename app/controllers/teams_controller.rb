class TeamsController < ApplicationController

  layout 'main'  
  helper :sort
  include SortHelper
  before_filter :authorize_admin  
  
  def index
    list
    render :action => 'list'
  end

  def list
    sort_init 'teams.name'
    sort_update
    @teams = Team.paginate :page => params[:page], :per_page => session_get(:items_per_page), 
      :order => sort_clause, :include => [:league, :level]
  end

  def new
    @team = Team.new
  end

  def create
    @team = Team.new(params[:team])
    if @team.save
      flash[:notice] = 'Team was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @team = Team.find(params[:id])
  end

  def update
    @team = Team.find(params[:id])
    if @team.update_attributes(params[:team])
      flash[:notice] = 'Team was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    name = "Record ##{params[:id]}"
    begin
      team = Team.find(params[:id])      
      name = "#{team.level}: #{team.name}"
      team.destroy
      flash[:notice] = "Team '#{name}' was successfully deleted."
    rescue
      flash[:notice] = "Error deleting team '#{name}'."
    end
    redirect_to :action => 'list'
  end
end
