class Barbeque::JobDefinition < Barbeque::ApplicationRecord
  belongs_to :app
  has_many :job_executions, dependent: :destroy
  has_one :slack_notification, dependent: :destroy

  validates :job, uniqueness: { scope: :app_id }

  attr_readonly :app_id
  attr_readonly :job

  serialize :command, Array

  accepts_nested_attributes_for :slack_notification, allow_destroy: true
end
