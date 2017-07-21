require 'barbeque/message_handler/job_execution'

module Barbeque
  module MessageHandler
    class Notification < JobExecution
      # @param [Barbeque::Message::Notification] message
      # @param [Barbeque::MessageQueue] message_queue
      def initialize(message:, message_queue:)
        @message = message
        @message_queue = message_queue

        subscription = SNSSubscription.find_by!(topic_arn: @message.topic_arn, job_queue_id: @message_queue.job_queue.id)
        @message.set_params_from_subscription(subscription)
      end
    end
  end
end
