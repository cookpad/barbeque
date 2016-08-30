class Barbeque::SlackNotification < Barbeque::ApplicationRecord
  belongs_to :job_definition, optional: true

  validates :channel, presence: true
end
