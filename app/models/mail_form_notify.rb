class MailFormNotify < ActionMailer::Base
  
  def send_form(form_info, config)
    @recipients = check_email(form_info[:email_to], config) || config[:signup_cc_to]
    @from       = config[:email_from]
    @sent_on    = Time.now
    @headers['Content-Type'] = "text/html; charset=#{UserSystem::CONFIG[:mail_charset]}; format=flowed"
    content_type "text/html"
    
    # Email header info
    form_name_array = form_info.find {|key, value| key.include?('form_name')}
    if form_name_array
      @subject = "#{config[:site_name]} - #{form_name_array[1]}"
    else
      @subject = "#{config[:site_name]} - Form"
    end
    
    # Email body substitutions
    @body["app_name"] = config[:site_name]
    form_info.delete(:email_to)
    @body["form_info"] = form_info
  end
  
  #-------------
  private
  
  def check_email(email_list, config)
    return nil if email_list.blank?
    
    ok_emails = emails_to_a(config[:signup_cc_to]) + emails_to_a(config[:email_from])
    ok_emails.uniq!
    ok_domains = ok_emails.map {|email| email_domain(email) }
  
    emails = emails_to_a(email_list)
    emails = emails.select {|email| ok_domains.include?(email_domain(email)) }
    emails = nil if emails.empty?
    emails
  end
  
  def emails_to_a(emails)
    emails.scan(/\b#{EMAIL_VALID_RE_STR}\b/mi)
  end
  
  def email_domain(email)
    email.gsub(/.*@(.*)/, '\1').downcase
  end
  
end
