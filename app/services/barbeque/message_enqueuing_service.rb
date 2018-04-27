require 'aws-sdk-sqs'

class Barbeque::MessageEnqueuingService
  DEFAULT_QUEUE = ENV['BARBEQUE_DEFAULT_QUEUE'] || 'default'
  VERIFY_ENQUEUED_JOBS = ENV['BARBEQUE_VERIFY_ENQUEUED_JOBS'] || '0'

  class BadRequest < StandardError
  end

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
    queue_url = Barbeque::JobQueue.queue_url_from_name(@queue)
    if VERIFY_ENQUEUED_JOBS == '1'
      unless Barbeque::JobDefinition.joins(:app).merge(Barbeque::App.where(name: @application)).where(job: @job).exists?
        raise BadRequest.new("JobDefinition '#{@job}' isn't defined in '#{@application}' application")
      end
    end
    response = Barbeque::MessageEnqueuingService.sqs_client.send_message(
      queue_url:    queue_url,
      message_body: build_message.to_json,
    )
    response.message_id
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
