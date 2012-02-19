class SurveysController < ApplicationController
  
  layout 'main'  
  helper :sort
  include SortHelper
  before_filter :authorize_admin, :except => [:save_answers]
  
  def index
    list
    render :action => 'list'
  end
  
  def list
    sort_init 'name'
    sort_update
    @surveys = Survey.paginate :page => params[:page], :per_page => session_get(:items_per_page), 
      :order => sort_clause
  end
  
  def new
    @survey = Survey.new
  end
  
  def create
    @survey = Survey.new(params[:survey])
    if @survey.save
      flash[:notice] = 'Survey was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end
  
  def edit
    @survey = Survey.find(params[:id])
  end
  
  def update
    @survey = Survey.find(params[:id])
    if @survey.update_attributes(params[:survey])
      flash[:notice] = 'Survey was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    name = "Record ##{params[:id]}"
    begin
      survey = Survey.find(params[:id])      
      name = "#{survey.name}"
      survey.destroy
      flash[:notice] = "Survey '#{name}' was successfully deleted."
    rescue
      flash[:notice] = "Error deleting Survey '#{name}'."
    end
    redirect_to :action => 'list'
  end

  #-----------
  # Methods with public authorization
  
  def save_answers
    survey = Survey.find(params[:survey_id])
    answer = survey.find_response_or_create(@user, session)
    
    if answer.submitter_name.blank? && params[:answers][:submitter_name]
      answer.update_attributes!(:submitter_name => params[:answers][:submitter_name])
    end    
    
    answer.save_answers(params[:answers])  
	if survey.submit_page.include?('/')
      redirect_to(survey.submit_page)
	else
      redirect_to(:controller => 'wiki', :action => 'show', :id => survey.submit_page)
	end
  end  
  
end
