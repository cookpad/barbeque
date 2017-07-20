require 'aws-sdk'
require 'barbeque/config'
require 'barbeque/message'

module Barbeque
  class MessageQueue
    class ExtendVisibilityError < StandardError
    end

    attr_reader :job_queue

    def initialize(queue_name)
      @job_queue = Barbeque::JobQueue.find_by!(name: queue_name)
      @messages  = []
      @stop      = false
    end

    # Receive a message and delete them all from SQS queue immediately.
    # @return [Barbeque::Message::Base]
    def dequeue
      while valid_messages.empty?
        return nil if @stop
        messages = receive_messages
        messages = reject_invalid_messages(messages)
        valid_messages.concat(messages)
      end

      message = valid_messages.shift
      # XXX: #receive_messages returns one message at most because it calls
      #       receive_message API without max_number_of_messages option.
      unless valid_messages.empty?
        extend_visibility_timeout(valid_messages)
      end
      message
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

    def receive_messages
      result = client.receive_message(
        queue_url: @job_queue.queue_url,
        wait_time_seconds: Barbeque.config.sqs_receive_message_wait_time,
      )
      result.messages.map { |m| Barbeque::Message.parse(m) }
    end

    def reject_invalid_messages(messages)
      messages, invalid_messages = messages.partition(&:valid?)
      invalid_messages.each { |m| delete_message(m) }
      messages
    end

    def extend_visibility_timeout(messages)
      resp = client.change_message_visibility_batch(
        queue_url: @job_queue.queue_url,
        entries: messages.map { |message| { id: message.message_id, receipt_handle: message.receipt_handle, visibility_timeout: 60 } },
      )
      unless resp.failed.empty?
        raise "Failed to extend visibility timeout: #{resp.failed.map(&:inspect)}"
      end
      nil
    end

    def valid_messages
      @valid_messages ||= []
    end

    def client
      @client ||= Aws::SQS::Client.new
    end
  end
end
