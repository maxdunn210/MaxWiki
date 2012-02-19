class MailerSubscription < MaxWikiActiveRecord

  belongs_to :wiki
  belongs_to :mailer
  belongs_to :user
end
