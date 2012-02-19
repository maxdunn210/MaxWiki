module EventsHelper

  include CalendarHelper

  def format_notes(event, team)
    note1 = ''
    note2 = ''
    team_id = team.nil? ? nil : team.id
    
    note1 = event.note unless event.note.nil?
    
    if event.home_team_id == team_id and event.home_team_note
      note2 = event.home_team_note
    elsif event.visitor_team_id == team_id and event.visitor_team_note
      note2 = event.visitor_team_note
    end
    
    if note1.empty? or note2.empty?
      note1 + note2
    else
      note1 + "<br>" + note2
    end
  end
 
  def format_event_date(d, options = {})
    return '' if d.nil?
    
    format = ''
    format << d.strftime('%a') + '<br />' unless options[:supress_day]
    format << d.strftime('%m/').gsub(/^0(.*)$/, '\1')
    format << d.strftime('%d').gsub(/^0(.*)$/, '\1')
    format << d.strftime('/%y') if options[:include_year]
    format
  end
  
  def format_event_time(t)  
    return '' if t.nil?
    
	if t.hour == 0 
	  '(TBD)'
	elsif t.hour == 1
	  ''
	else
	  t.strftime('%I:%M%p').gsub(/^0(.*)$/, '\1')
	end  
  end
  
  def format_event_duration(duration)
    return '' if duration.nil? or duration.zero?
    
    hours = (duration / 60)
    mins = duration - hours * 60
    if hours == 0
      duration_string = "#{mins}mins"
    elsif mins == 30 
      duration_string = "#{hours}.5hrs"
    else
      hours_suffix = (hours == 1 ? "hr" : "hrs")
      duration_string = "#{hours}#{hours_suffix}"
      unless mins.zero?
        duration_string << " #{mins}mins"
      end  
    end  
    duration_string
  end
  
  def format_event_time_and_duration(time, duration, options = {})
    return '' if time.nil?

    duration_not_present = duration.nil? or duration.zero?
    format = format_event_time(time)
    unless format.empty? or duration_not_present 
      if options[:no_break]
        format << " for "
      else  
        format << "<br />" 
      end
    end
    format << format_event_duration(duration) unless duration_not_present
    format
  end
  
  def add_buttons(kinds)
    return '' if !Role.check_role(ROLE_EDITOR) or kinds.nil?
      
    html = "<table>\n"
    html << "  <tr>\n"
    kinds.each {|kind| html << add_button(kind) }
    html << "  </tr>\n"
    html << "</table>\n"
    html
  end

  def add_button(kind)
    prefix1 = "    "
    prefix2 = "      "
    html = prefix1 + "<td>\n"
    html << prefix2 + form_tag(:controller => 'events', 
      :action => 'new', :kind => kind) + "\n"
	html << prefix2 + submit_tag("Add #{kind}") + "&nbsp;\n"
	html << prefix2 + end_form + "\n"
    html << prefix1 + "</td>"
    html
  end
end
