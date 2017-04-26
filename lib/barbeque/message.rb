require 'barbeque/exception_handler'
require 'barbeque/message/base'
require 'barbeque/message/invalid_message'
require 'barbeque/message/job_execution'
require 'barbeque/message/job_retry'

module Barbeque
  module Message
    class << self
      # @param [Aws::SQS::Types::Message] raw_message
      # @return [Barbeque::Message::Base]
      def parse(raw_message, job_queue:)
        body = JSON.parse(raw_message.body)
        if body['Type'] == 'Notification'
          Barbeque::Message::JobExecution.create_message_from_sns_notification(raw_message, body, job_queue: job_queue)
        else
          klass = find_class(body['Type'])
          klass.new(raw_message, body)
        end
      rescue JSON::ParserError => e
        ExceptionHandler.handle_exception(e)
        InvalidMessage.new(raw_message, {})
      end

      private

      def find_class(type)
        Message.const_get(type, false)
      rescue NameError => e
        ExceptionHandler.handle_exception(e)
        InvalidMessage
      end
    end
  end
end
