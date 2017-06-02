require 'barbeque/message/base'

module Barbeque
  module Message
    class Notification < Base
      attr_reader :body        # [Object] free-format JSON
      attr_reader :topic_arn   # [String] To specify `subscription.topic_arn`
      attr_reader :application # [String] To specify `job_definitions.app.name`
      attr_reader :job         # [String] To specify `job_definitions.job`

      # @param [Barneque::SNSSubscription] subscription
      # @return [Barbeque::Message::Notification]
      def set_params_from_subscription(subscription)
        @application = subscription.app.name
        @job = subscription.job_definition.job
        self
      end

      private

      def assign_body(message_body)
        super
        @topic_arn = message_body['TopicArn']
        @body = JSON.parse(message_body['Message'])
      end
    end
  end
end
