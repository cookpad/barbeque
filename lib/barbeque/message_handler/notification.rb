require 'barbeque/message_handler/job_execution'

module Barbeque
  module MessageHandler
    class Notification < JobExecution
      # @param [Barbeque::Message::Notification] message
      # @param [Barbeque::JobQueue] job_queue
      def initialize(message:, job_queue:)
        @message = message
        @job_queue = job_queue

        subscription = SNSSubscription.find_by!(topic_arn: @message.topic_arn, job_queue_id: @job_queue.id)
        @message.set_params_from_subscription(subscription)
      end
    end
  end
end
