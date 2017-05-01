class Barbeque::JobRetry < Barbeque::ApplicationRecord
  belongs_to :job_execution
  has_one :job_definition, through: :job_execution
  has_one :app, through: :job_definition
  has_one :slack_notification, through: :job_execution

  enum status: {
    pending: 0,
    success: 1,
    failed:  2,
    retried: 3,
    error: 4,
  }

  # @return [Hash] - A hash created by `JobExecutor::Retry#log_result`
  def execution_log
    @execution_log ||= Barbeque::ExecutionLog.load(execution: self)
  end

  def to_resource
    Barbeque::Api::JobRetryResource.new(self)
  end
end
