class Barbeque::JobExecution < Barbeque::ApplicationRecord
  belongs_to :job_definition
  belongs_to :job_queue
  has_one :slack_notification, through: :job_definition
  has_one :app, through: :job_definition
  has_many :job_retries, dependent: :destroy

  enum status: {
    pending: 0,
    success: 1,
    failed:  2,
    retried: 3,
  }

  paginates_per 15

  # @return [Hash] - A hash created by `JobExecutor::Job#log_result`
  def execution_log
    @execution_log ||= Barbeque::ExecutionLog.load(execution: self)
  end

  def to_resource
    Barbeque::Api::JobExecutionResource.new(self)
  end
end
