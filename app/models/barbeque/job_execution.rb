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
    error: 4,
    running: 5,
  }

  paginates_per 15

  # @return [Hash] - A hash created by `JobExecutor::Job#log_result`
  def execution_log
    @execution_log ||= Barbeque::ExecutionLog.load(execution: self)
  end

  def retryable?
    failed? || error?
  end

  def to_param
    message_id
  end
end
