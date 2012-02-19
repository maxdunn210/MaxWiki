class Mailer < MaxWikiActiveRecord

  belongs_to :wiki
  belongs_to :mailer_group
  has_many :emails
end
