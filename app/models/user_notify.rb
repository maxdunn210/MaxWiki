class UserNotify < ActionMailer::Base
  def signup(user, url, config, recipient = nil)
    setup_header("Account Activation", user, config, recipient)
    setup_body(user, url, config)
    @body["user"] = user
  end

  def imported(user, url, password, config)
    setup_header("Account Created", user, config)
    setup_body(user, url, config)
    @body[:password] = password
    @body["user"] = user
  end

  def reset_password(user, url, config)
    setup_header("Password Reset", user, config)
    setup_body(user, url, config)
  end

  def change_password(user, url, config)
    setup_header("Changed Password Notification", user, config)
    setup_body(user, url, config)
  end

  def pending_delete(user, url, config)
    setup_header("Delete User Notification", user, config)
    setup_body(user, url, config)
  end

  def delete(user, url, config)
    setup_header("Delete User Notification", user, config)
    setup_body(user, url, config)
  end

private

  def setup_header(subject, user, config, recipient = nil)
    @recipients = recipient || "#{user.email}"
    @from       = config[:email_from]
    @subject    = "#{config[:site_name]}: #{subject}"
    @sent_on    = Time.now
    @headers['Content-Type'] = "text/plain; charset=#{UserSystem::CONFIG[:mail_charset]}; format=flowed"
    content_type "text/plain"
  end

  def setup_body(user, url, config)
    @body["name"] = "#{user.firstname} #{user.lastname}"
    @body["url"] = url
    @body["app_name"] = config[:site_name].to_s
    @body["login"] = user.login
  end
  
end
