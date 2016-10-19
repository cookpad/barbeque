require 'aws-sdk'

class Barbeque::MessageRetryingService
  DEFAULT_DELAY_SECONDS = 0

  def self.sqs_client
    @sqs_client ||= Aws::SQS::Client.new
  end

  def initialize(message_id:, delay_seconds: nil)
    @message_id    = message_id
    @delay_seconds = delay_seconds || DEFAULT_DELAY_SECONDS
  end

  def run
    execution = Barbeque::JobExecution.find_by!(message_id: @message_id)
    Barbeque::MessageRetryingService.sqs_client.send_message(
      queue_url:     execution.job_queue.queue_url,
      message_body:  build_message.to_json,
      delay_seconds: @delay_seconds,
    )
  end

  private

  def build_message
    {
      'Type'           => 'JobRetry',
      'RetryMessageId' => @message_id,
    }
  end
end
