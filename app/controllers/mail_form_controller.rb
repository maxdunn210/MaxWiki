class MailFormController < ApplicationController
  
  layout 'main'  
  
  def send_form
    begin
      @form_info = params.dup
      @form_info.delete_if {|key, value| ['submit', 'action', 'controller'].include?(key)}
      
      # If capcha field is anything but "Not Spam" then don't save
      if params[:capcha] && (params[:capcha].downcase.gsub(' ', '') != 'notspam')
        flash.now[:error] = "There was an error in the capcha field. Please press the browsers Back button and re-enter the information."
      else
        deliver_now { MailFormNotify.deliver_send_form(@form_info, @wiki.config) }
        @sent_ok = true
      end
    rescue StandardError => e
      flash.now[:error] = "There was an error sending the confirmation email: #{e}"
    end  
  end
  
end