require 'barbeque/message/base'

module Barbeque
  module Message
    class JobExecution < Base
      attr_reader :body        # [Object] free-format JSON
      attr_reader :application # [String] To specify `job_definitions.app.name`
      attr_reader :job         # [String] To specify `job_definitions.job`

      private

      def assign_body(message_body)
        super
        @application = message_body['Application']
        @job  = message_body['Job']
        @body = message_body['Message']
      end
    end
  end
end
