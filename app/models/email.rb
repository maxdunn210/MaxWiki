class Email < MaxWikiActiveRecord

  belongs_to :wiki
  belongs_to :user
  belongs_to :mailer
end
