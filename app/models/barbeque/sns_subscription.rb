module Barbeque
  class SNSSubscription < ApplicationRecord
    belongs_to :job_queue
    belongs_to :job_definition
    has_one :app, through: :job_definition

    validates :topic_arn,
      uniqueness: { scope: :job_queue, message: 'should be set with only one queue' },
      presence: true

    before_create :subscribe_topic!
    after_destroy :unsubscribe_topic!
    after_update :update_queue_policy!

    private

    def subscribe_topic!
      sqs_client = Aws::SQS::Client.new
      sqs_attrs = sqs_client.get_queue_attributes(
        queue_url: job_queue.queue_url,
        attribute_names: ['QueueArn'],
      )
      queue_arn = sqs_attrs.attributes['QueueArn']

      sns_client = Aws::SNS::Client.new
      sns_client.subscribe(
        topic_arn: topic_arn,
        protocol: 'sqs',
        endpoint: queue_arn
      )
    rescue Aws::SNS::Errors::NotFound
      errors[:topic_arn] << 'is not found'
      throw(:abort)
    end

    def unsubscribe_topic!
      sqs_client = Aws::SQS::Client.new
      sqs_attrs = sqs_client.get_queue_attributes(
        queue_url: job_queue.queue_url,
        attribute_names: ['QueueArn'],
      )
      queue_arn = sqs_attrs.attributes['QueueArn']

      sns_client = Aws::SNS::Client.new
      subscriptions = sns_client.list_subscriptions_by_topic(
        topic_arn: topic_arn,
      )
      subscription_arn = subscriptions.subscriptions.find {|subscription| subscription.endpoint. == queue_arn }.try!(:subscription_arn)
      if subscription_arn
        sns_client.unsubscribe(
          subscription_arn: subscription_arn,
        )
      end
    end

    def update_queue_policy!
      job_queue.update_policy!
    end
  end
end
