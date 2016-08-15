class Barbeque::Api::JobRetriesController < Barbeque::Api::ApplicationController
  include Garage::RestfulActions

  # http://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_SendMessage.html
  SQS_MAX_DELAY_SECONDS = 900

  validates :create do
    integer :delay_seconds, only: 0..SQS_MAX_DELAY_SECONDS
  end

  private

  def require_resources
    protect_resource_as Barbeque::Api::JobRetryResource
  end

  def create_resource
    result = retry_message
    JobRetry.new(message_id: result.message_id).to_resource
  end

  def retry_message
    MessageRetryingService.new(
      message_id: params[:job_execution_message_id],
      delay_seconds: params[:delay_seconds].to_i,
    ).run
  end
end
