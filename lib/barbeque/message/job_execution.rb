require 'barbeque/message/base'

module Barbeque
  module Message
    class JobExecution < Base
      attr_reader :body        # [Object] free-format JSON
      attr_reader :application # [String] To specify `job_definitions.application_id`
      attr_reader :job         # [String] To specify `job_definitions.name`

      # Creates JobExecution messages from a notification which came from subscribed SNS topic
      def self.create_message_from_sns_notification(raw_message, message_body, job_queue:)
        topic_arn = message_body['TopicArn']
        subscription = SNSSubscription.find_by!(topic_arn: topic_arn, job_queue_id: job_queue.id)
        body = {
          'Type' => 'JobExecution',
          'Application' => subscription.app.name,
          'Job' => subscription.job_definition.job,
          'Message' => message_body['Message'],
        }
        new(raw_message, body)
      end

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
