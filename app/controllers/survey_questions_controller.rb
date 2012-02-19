class SurveyQuestionsController < ApplicationController
  
  layout 'main'  
  helper :sort
  include SortHelper
  include SurveyControllerHelper
  before_filter :authorize_admin  
  
  def index
    list
    render :action => 'list', :survey_id => @survey_id
  end
  
  def list
    set_current_survey
    if @survey_id
      conditions = {:survey_id => @survey_id}
    else
      conditions = 'true'
    end
    
    sort_init 'survey_questions.name'
    sort_update
    @survey_questions = SurveyQuestion.paginate(:page => params[:page], :per_page => session_get(:items_per_page), 
    :order => sort_clause,
    :conditions => ['survey_id = ?', @survey.id],
    :include => :survey)
  end
  
  def new
    set_current_survey
    @survey_question = @survey.survey_questions.build
  end
  
  def create
    set_current_survey
    @survey_question = SurveyQuestion.new(params[:survey_question])
    if @survey_question.save
      flash[:notice] = 'SurveyQuestion was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end
  
  def edit
    @survey_question = SurveyQuestion.find(params[:id])
  end
  
  def update
    @survey_question = SurveyQuestion.find(params[:id])
    if @survey_question.update_attributes(params[:survey_question])
      flash[:notice] = 'SurveyQuestion was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    name = "Record ##{params[:id]}"
    begin
      survey_question = SurveyQuestion.find(params[:id])      
      name = "#{survey_question.name}"
      survey_question.destroy
      flash[:notice] = "SurveyQuestion '#{name}' was successfully deleted."
    rescue
      flash[:notice] = "Error deleting SurveyQuestion '#{name}'."
    end
    redirect_to :action => 'list'
  end

end
