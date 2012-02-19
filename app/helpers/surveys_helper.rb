module SurveysHelper
  
  def survey(name, options = {})
    survey = Survey.find(:first, :conditions => ['name = ?', name])
    if survey.nil?
      return "Survey '#{name}' not found"
    end
    existing_response = survey.find_response(@user, session)
    
    html = ''
    unless options[:submit] == false
      html << form_tag(:controller => 'surveys', :action => 'save_answers') 
    end
    html << "<input id='survey_id' name='survey_id' type='hidden' value='#{survey.id}' />"
    html << "<table>\n"
    
    survey.survey_questions.each do |question|
      
      # See if there is an existing answer
      answer_text = ''
      if !existing_response.nil?
        answer = existing_response.find_answer_by_question_id(question.id)
        if !answer.nil?
          answer_text = answer.answer
        end
      end
      
      # Setup the HTML options
      unless question.html_options.blank?
        html_options = eval("{#{question.html_options}}") rescue nil
      else
        html_options = {}
      end
      
      size = '40'
      name = "answers[#{question.id}]"
      html << "<tr>\n"
      html << "<td><label for='answer[#{question.id}]'>#{question.question}</label></td>\n"
      html << "<td>"
      if html_options.nil?
        html << "Bad html options '#{question.html_options}'"
      elsif question[:input_type] == 'select'
        html << select_tag(name, options_for_select(question.choices_to_a, answer_text), html_options)
      elsif question[:input_type] == 'text_area'
        html << text_area_tag(name, answer_text, html_options.merge({:cols => size}))
      elsif question[:input_type] == 'text_field'
        html << text_field_tag(name, answer_text, html_options.merge({:size => size}))
      else
        html << "Bad input type '#{question.input_type}'"
      end  
      html << "</td>\n"
      html << "</tr>\n"
    end
    html << "</table>\n"
    unless options[:submit] == false
      html << submit_tag('Save')
      html << end_form
    end
    html
  end
  
  def survey_results(name)
    survey = Survey.find(:first, :conditions => ['name = ?', name])
    if survey.nil?
      return  "Survey '#{name}' not found"
    end
    gathered_answers = survey.gather_answers
    response_num = survey.survey_responses.count
    
    summary = {}
    survey.survey_questions.each_with_index do |question, question_pos|
      if question.summable?
        summary[question.name] = {}
        choices = question.choices_to_a
        choices.each do |choice|
          num = gathered_answers.inject(0) {|sum, a| if a[:answers][question_pos] == choice then sum + 1 else sum end}
          summary[question.name][choice] = num
        end
      end
    end
    
    html = "<b>Survey '#{survey.name}' Summary</b>\n"
    html << "<p>Total responses=#{response_num}</p>"
    html << "<table>\n"
    summary.each do |question_name, choices|
      html << "<tr>\n"
      html << "<td>"
      html << "#{question_name}:"
      html << "</td><td>"
      choices.each do |choice_name, num|
        html << "#{choice_name}=#{percent(num, response_num)}, "
      end
      html << "</td>\n"
      html << "</tr>\n"
    end
    html << "</table>\n"
    html
  end
  
 
  #-------------------
  private
  
  def percent(num, total)
    if total == 0
      '0%'
    else  
     (num*100 / total).round.to_s + '%'
    end
  end
  
end
