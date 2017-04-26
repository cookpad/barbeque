class Barbeque::JobQueue < Barbeque::ApplicationRecord
  SQS_NAME_PREFIX = ENV['BARBEQUE_SQS_NAME_PREFIX'] || 'Barbeque-'
  SQS_NAME_MAX_LENGTH = 80

  has_many :sns_subscriptions, class_name: 'SNSSubscription', dependent: :destroy

  # All SQS queues' "ReceiveMessageWaitTimeSeconds" are configured to be 20s (maximum).
  # This should be as large as possible to reduce API-calling cost by long polling.
  # http://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_CreateQueue.html#API_CreateQueue_RequestParameters
  SQS_RECEIVE_MESSAGE_WAIT_TIME = 20

  # SQS queue allows [a-zA-Z0-9_-]+ as queue name. Its maximum length is 80.
  validates :name, presence: true, uniqueness: true, format: /\A[a-zA-Z0-9_-]+\z/,
    length: { maximum: SQS_NAME_MAX_LENGTH - SQS_NAME_PREFIX.length }

  attr_readonly :name

  def sqs_queue_name
    SQS_NAME_PREFIX + name
  end

  def update_policy!
    client = Aws::SQS::Client.new
    attrs = client.get_queue_attributes(
      queue_url: queue_url,
      attribute_names: ['QueueArn'],
    )
    queue_arn = attrs.attributes['QueueArn']
    topic_arns = sns_subscriptions.map(&:topic_arn)
    if topic_arns.present?
      policy = generate_policy(queue_arn: queue_arn, topic_arns: topic_arns)
    end

    client.set_queue_attributes(
      queue_url: queue_url,
      attributes: { 'Policy' => policy },
    )
  end

  private

  # @paaram [String] queue_arn
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
end
