require 'aws-sdk'

class Barbeque::MessageEnqueuingService
  DEFAULT_QUEUE = ENV['BARBEQUE_DEFAULT_QUEUE'] || 'default'

  def self.sqs_client
    @sqs_client ||= Aws::SQS::Client.new
  end

  # @param [String] application
  # @param [String] job
  # @param [Object] message
  # @param [String] queue
  def initialize(application:, job:, message:, queue: nil)
    @application = application
    @job         = job
    @queue       = queue || DEFAULT_QUEUE
    @message     = message
  end

  # @return [String] message_id
  def run
    queue = Barbeque::JobQueue.find_by!(name: @queue)
    response = Barbeque::MessageEnqueuingService.sqs_client.send_message(
      queue_url:    queue.queue_url,
      message_body: build_message.to_json,
    )
    message_id = response.message_id
    Barbeque::ExecutionLog.save_message(@application, @job, message_id, @message.to_json)
    message_id
  end

  private

  def build_message
    {
      'Type'        => 'JobExecution',
      'Application' => @application,
      'Job'         => @job,
      'Message'     => @message,
    }
  end
end
