require 'aws-sdk-sns'
require 'aws-sdk-sqs'

class Barbeque::SnsSubscriptionService
  def self.sqs_client
    @sqs_client ||= Aws::SQS::Client.new
  end

  def self.sns_client
    @sns_client ||= Aws::SNS::Client.new
  end

  # @param [Barbeque::SnsSubscription] sns_subscription
  # @return [Boolean] `true` if succeeded to subscribe
  def subscribe(sns_subscription)
    if sns_subscription.valid?
      begin
        subscribe_topic!(sns_subscription)
        sns_subscription.save!
        update_sqs_policy!(sns_subscription)
        true
      rescue Aws::SNS::Errors::AuthorizationError
        sns_subscription.errors.add(:topic_arn, 'is not authorized')
        false
      rescue Aws::SNS::Errors::NotFound
        sns_subscription.errors.add(:topic_arn, 'is not found')
        false
      end
    else
      false
    end
  end

  # @param [Barbeque::SnsSubscription] sns_subscription
  def unsubscribe(sns_subscription)
    sns_subscription.destroy
    update_sqs_policy!(sns_subscription)
    unsubscribe_topic!(sns_subscription)
    nil
  end

  private

  def sqs_client
    Barbeque::SnsSubscriptionService.sqs_client
  end

  def sns_client
    Barbeque::SnsSubscriptionService.sns_client
  end

  # @param [Barbeque::SnsSubscription] sns_subscription
  def update_sqs_policy!(sns_subscription)
    attrs = sqs_client.get_queue_attributes(
      queue_url: sns_subscription.job_queue.queue_url,
      attribute_names: ['QueueArn'],
    )
    queue_arn = attrs.attributes['QueueArn']
    topic_arns = sns_subscription.job_queue.sns_subscriptions.map(&:topic_arn)

    if topic_arns.present?
      policy = generate_policy(queue_arn: queue_arn, topic_arns: topic_arns)
    else
      policy = '' # Be blank when there're no subscriptions.
    end

    sqs_client.set_queue_attributes(
      queue_url: sns_subscription.job_queue.queue_url,
      attributes: { 'Policy' => policy },
    )
  end

  # @param [String] queue_arn
  # @param [Array<String>] topic_arns
  # @return [String] JSON formatted policy
  def generate_policy(queue_arn:, topic_arns:)
    {
      'Version' => '2012-10-17',
      'Statement' => [
        'Effect' => 'Allow',
        'Principal' => '*',
        'Action' => 'sqs:SendMessage',
        'Resource' => queue_arn,
        'Condition' => {
          'ArnEquals' => {
            'aws:SourceArn' => topic_arns,
          }
        }
      ]
    }.to_json
  end

  # @param [Barbeque::SnsSubscription] sns_subscription
  def subscribe_topic!(sns_subscription)
    sqs_attrs = sqs_client.get_queue_attributes(
      queue_url: sns_subscription.job_queue.queue_url,
      attribute_names: ['QueueArn'],
    )
    queue_arn = sqs_attrs.attributes['QueueArn']

    sns_client.subscribe(
      topic_arn: sns_subscription.topic_arn,
      protocol: 'sqs',
      endpoint: queue_arn
    )
  end

  # @param [Barbeque::SnsSubscription] sns_subscription
  def unsubscribe_topic!(sns_subscription)
    sqs_attrs = sqs_client.get_queue_attributes(
      queue_url: sns_subscription.job_queue.queue_url,
      attribute_names: ['QueueArn'],
    )
    queue_arn = sqs_attrs.attributes['QueueArn']

    subscriptions = sns_client.list_subscriptions_by_topic(
      topic_arn: sns_subscription.topic_arn,
    )
    subscription_arn = subscriptions.subscriptions.find {|subscription| subscription.endpoint == queue_arn }.try!(:subscription_arn)

    if subscription_arn
      sns_client.unsubscribe(
        subscription_arn: subscription_arn,
      )
    end
  end

end
