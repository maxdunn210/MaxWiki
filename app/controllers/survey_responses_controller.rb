class SurveyResponsesController < ApplicationController
  
  layout 'main'  
  helper :sort
  include SortHelper
  include SurveyControllerHelper
  before_filter :authorize_admin
  
  def index
    list
    render :action => 'list'
  end
  
  def list
    set_current_survey
    sort_init 'survey_responses.survey_id'
    sort_update
    @survey_responses = SurveyResponse.paginate(:page => params[:page], :per_page => session_get(:items_per_page), 
    :conditions => ['survey_id = ?', @survey.id],
    :order => sort_clause)
  end
  
  def new
    set_current_survey
    @survey_response = @survey.survey_responses.build
  end
  
  def create
    set_current_survey
    @survey_response = SurveyResponse.new(params[:survey_response])
    if @survey_response.save
      @survey.survey_responses << @survey_response
      @survey_response.save_answers(params[:answers])
      flash[:notice] = 'SurveyResponse was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end
  
  def edit
    @survey_response = SurveyResponse.find(params[:id])
  end
  
  def update
    @survey_response = SurveyResponse.find(params[:id])
    @survey_response.save_answers(params[:answers])
    
    if @survey_response.update_attributes(params[:survey_response])
      flash[:notice] = 'Survey Response was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    name = "Record ##{params[:id]}"
    begin
      survey_response = SurveyResponse.find(params[:id])      
      survey_response.destroy
      flash[:notice] = "Survey Response '#{name}' was successfully deleted."
    rescue
      flash[:notice] = "Error deleting Survey Response '#{name}'."
    end
    redirect_to :action => 'list'
  end
  
  def export
    set_current_survey
    @survey_questions = @survey.survey_questions
    @survey_gathered = @survey.gather_answers
    render :action => 'export', :layout => false
  end
  
end
