class RegNotifyPlayer < ActionMailer::Base
  def signup_player(player, household, adult1, adult2, doctor, emer_contact, from, url, config)
    setup_email(adult1, from, config)

    # Email header info
    @subject += "Registration received for #{player.firstname} #{player.lastname}"

    # Email body substitutions
    @body["app_name"] = config[:site_name]
    @body["url"] = url
    @body["username"] = "#{adult1.firstname} #{adult2.lastname}"
    @body["player"] = player
    @body["household"] = household
    @body["adult1"] = adult1
    @body["adult2"] = adult2
    @body["doctor"] = doctor
    @body["emer_contact"] = emer_contact
  end

  def setup_email(user, from, config)
    @recipients = "#{user.email}"
    @from       = from
    @subject    = "[#{config[:site_name]}] "
    @sent_on    = Time.now
    @headers['Content-Type'] = "text/html; charset=#{UserSystem::CONFIG[:mail_charset]}; format=flowed"
    content_type "text/html"
  end
end
