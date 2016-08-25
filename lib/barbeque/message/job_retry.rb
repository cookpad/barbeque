require 'barbeque/message/base'

module Barbeque
  module Message
    class JobRetry < Base
      attr_reader :retry_message_id # [String] JobExection's message_id

      private

      def assign_body(message_body)
        super
        @retry_message_id = message_body['RetryMessageId']
      end
    end
  end
end
