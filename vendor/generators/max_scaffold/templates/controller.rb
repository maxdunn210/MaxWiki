class <%= controller_class_name %>Controller < ApplicationController

  layout 'main'  
  helper :sort
  include SortHelper
  before_filter :authorize_admin  
  
  def index
    list
    render :action => 'list'
  end

<% for action in unscaffolded_actions -%>
  def <%= action %>
  end

<% end -%>
  def list
    sort_init '<%= eval(model_name, TOPLEVEL_BINDING).content_columns[0].name %>'
    sort_update
    @<%= singular_name %>_pages, @<%= plural_name %> = paginate :<%= plural_name %>, 
      :per_page => saved_items_per_page, :order => sort_clause
  end

  def new
    @<%= singular_name %> = <%= model_name %>.new
  end

  def create
    @<%= singular_name %> = <%= model_name %>.new(params[:<%= singular_name %>])
    if @<%= singular_name %>.save
      flash[:notice] = '<%= model_name %> was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @<%= singular_name %> = <%= model_name %>.find(params[:id])
  end

  def update
    @<%= singular_name %> = <%= model_name %>.find(params[:id])
    if @<%= singular_name %>.update_attributes(params[:<%= singular_name %>])
      flash[:notice] = '<%= model_name %> was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    name = "Record ##{params[:id]}"
    begin
      <%= singular_name %> = <%= model_name %>.find(params[:id])      
      name = "#{<%= singular_name %>.name}"
      <%= singular_name %>.destroy
      flash[:notice] = "<%= model_name %> '#{name}' was successfully deleted."
    rescue
      flash[:notice] = "Error deleting <%= model_name %> '#{name}'."
    end
    redirect_to :action => 'list'
  end

end
