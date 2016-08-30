require 'aws-sdk'
require 'barbeque/message'

module Barbeque
  class MessageQueue
    attr_reader :job_queue

    def initialize(queue_name)
      @job_queue = Barbeque::JobQueue.find_by!(name: queue_name)
      @messages  = []
      @stop      = false
    end

    # Receive a message and delete them all from SQS queue immediately.
    # TODO: Stop removing them immediately to implement retry.
    # @return [Barbeque::Message::Base]
    def dequeue
      while valid_messages.empty?
        return nil if @stop
        messages = receive_messages
        messages = reject_invalid_messages(messages)
        valid_messages.concat(messages)
      end

      valid_messages.shift.tap do |message|
        delete_message(message)
      end
    end

    def stop!
      @stop = true
    end

    private

    def receive_messages
      result = client.receive_message(
        queue_url: @job_queue.queue_url,
        wait_time_seconds: Barbeque::JobQueue::SQS_RECEIVE_MESSAGE_WAIT_TIME,
      )
      result.messages.map { |m| Barbeque::Message.parse(m) }
    end

    def reject_invalid_messages(messages)
      messages, invalid_messages = messages.partition(&:valid?)
      invalid_messages.each { |m| delete_message(m) }
      messages
    end

    # Remove a message from SQS queue.
    def delete_message(message)
      client.delete_message(
        queue_url:      @job_queue.queue_url,
        receipt_handle: message.receipt_handle,
      )
    end

    def valid_messages
      @valid_messages ||= []
    end

    def client
      @client ||= Aws::SQS::Client.new
    end
  end
end
