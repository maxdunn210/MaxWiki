module SurveyControllerHelper

  def set_current_survey
    unless params[:survey_id].blank?
      session[:survey_id] = params[:survey_id]
    end  
    survey_id = session[:survey_id]
    @survey = Survey.find(survey_id)
  end

end