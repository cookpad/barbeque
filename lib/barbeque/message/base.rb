module Barbeque
  module Message
    # A model wrapping Aws::SQS::Types::Message.
    class Base
      attr_reader :id             # [String] Barbeque::JobExecution is associated via `message_id`
      attr_reader :receipt_handle # [String] Used to ack a message
      attr_reader :type           # [String] "JobExecution", "JobRetry", etc
      attr_reader :sent_timestamp # [String] The time the message was sent to the queue (epoch time in milliseconds)

      # @param [Aws::SQS::Types::Message] raw_message
      # @param message_body [Hash] parse result of `raw_message.body`
      def initialize(raw_message, message_body)
        assign_body(message_body)
        @id             = raw_message.message_id
        @receipt_handle = raw_message.receipt_handle
        @sent_timestamp = raw_message.attributes['SentTimestamp']
      end

      # To distinguish with `Barbeque::Message::InvalidMessage`
      def valid?
        true
      end

      private

      def assign_body(message_body)
        @type = message_body['Type']
      end
    end
  end
end
