class MailerGroup < MaxWikiActiveRecord

  belongs_to :wiki
  has_one :mailer
end
