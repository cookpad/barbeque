require 'barbeque/message/base'
require 'barbeque/message/invalid_message'
require 'barbeque/message/job_execution'
require 'barbeque/message/job_retry'

module Barbeque
  module Message
    class << self
      # @param [Aws::SQS::Types::Message] raw_message
      # @return [Barbeque::Message::Base]
      def parse(raw_message)
        body = JSON.parse(raw_message.body)
        klass = find_class(body['Type'])
        klass.new(raw_message, body)
      rescue JSON::ParserError
        InvalidMessage.new(raw_message, {})
      end

      private

      def find_class(type)
        Message.const_get(type, false)
      rescue NameError
        InvalidMessage
      end
    end
  end
end
