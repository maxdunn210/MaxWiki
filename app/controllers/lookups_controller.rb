class LookupsController < ApplicationController
  
  layout 'main'  
  helper :sort
  include SortHelper
  before_filter :authorize_admin  
  
  def index
    list_lookups
    render :action => 'list_lookups'
  end
  
  def list_lookups
    sort_init 'kind'
    sort_update
    @lookups = Lookup.paginate(:page => params[:page], :per_page => session_get(:items_per_page), 
    :order => sort_clause)
  end
  
  def new_lookup
    @lookup = Lookup.new
  end
  
  def create_lookup
    @lookup = Lookup.new(params[:lookup])
    if @lookup.save
      flash[:notice] = 'Lookup was successfully created.'
      redirect_to :action => 'list_lookups'
    else
      render :action => 'new_lookup'
    end
  end
  
  def edit_lookup
    @lookup = Lookup.find(params[:id])
  end
  
  def update_lookup
    @lookup = Lookup.find(params[:id])
    if @lookup.update_attributes(params[:lookup])
      flash[:notice] = 'Lookup was successfully updated.'
      redirect_to :action => 'list_lookups'
    else
      render :action => 'edit_lookup'
    end
  end
  
  def destroy_lookup
    name = "Record ##{params[:id]}"
    begin
      lookup = Lookup.find(params[:id])      
      name = "#{lookup.name}"
      lookup.destroy
      flash[:notice] = "Lookup '#{name}' was successfully deleted."
    rescue
      flash[:notice] = "Error deleting lookup '#{name}'."
    end
    redirect_to :action => 'list_lookups'
  end
  
end
