require 'job_executor/storage'

class JobExecution < ApplicationRecord
  belongs_to :job_definition
  belongs_to :job_queue
  has_one :slack_notification, through: :job_definition
  has_one :app, through: :job_definition
  has_many :job_retries

  enum status: {
    pending: 0,
    success: 1,
    failed:  2,
    retried: 3,
  }

  paginates_per 15

  def to_resource
    Api::JobExecutionResource.new(self)
  end
end
