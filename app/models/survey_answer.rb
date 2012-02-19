class SurveyAnswer < MaxWikiActiveRecord
  belongs_to :wiki
  belongs_to :survey_response
  belongs_to :survey
  has_one :survey_question
end
