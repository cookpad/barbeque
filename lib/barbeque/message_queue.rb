require 'aws-sdk-sqs'
require 'barbeque/config'
require 'barbeque/message'

module Barbeque
  class MessageQueue
    attr_reader :job_queue

    def initialize(queue_name)
      @job_queue = Barbeque::JobQueue.find_by!(name: queue_name)
      @messages  = []
      @stop      = false
    end

    # Receive a message from SQS queue.
    # @return [Barbeque::Message::Base]
    def dequeue
      loop do
        return nil if @stop
        message = receive_message
        if message
          if message.valid?
            return message
          else
            delete_message(message)
          end
        end
      end
    end

    # Remove a message from SQS queue.
    # @param [Barbeque::Message::Base] message
    def delete_message(message)
      client.delete_message(
        queue_url: @job_queue.queue_url,
        receipt_handle: message.receipt_handle,
      )
    end

    def stop!
      @stop = true
    end

    private

    def receive_message
      result = client.receive_message(
        queue_url: @job_queue.queue_url,
        wait_time_seconds: Barbeque.config.sqs_receive_message_wait_time,
        max_number_of_messages: 1,
      )
      if result.messages[0]
        Barbeque::Message.parse(result.messages[0])
      end
    end

    def client
      @client ||= Aws::SQS::Client.new
    end
  end
end
