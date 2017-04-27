class Barbeque::SnsSubscriptionsController < Barbeque::ApplicationController
  def index
    @sns_subscriptions = Barbeque::SNSSubscription.all
  end

  def show
    @sns_subscription = Barbeque::SNSSubscription.find(params[:id])
  end

  def new
    @sns_topic_arns = fetch_sns_topic_arns
    @sns_subscription = Barbeque::SNSSubscription.new
  end

  def edit
    @sns_subscription = Barbeque::SNSSubscription.find(params[:id])
  end

  def create
    @sns_subscription = Barbeque::SNSSubscription.new(params.require(:sns_subscription).permit(:topic_arn, :job_queue_id, :job_definition_id))
    if @sns_subscription.valid?
      begin
        subscribe_topic!
      rescue Aws::SNS::Errors::AuthorizationError
        @sns_subscription.errors[:topic_arn] << 'is not authorized'
        @sns_topic_arns = fetch_sns_topic_arns
        render :new
      rescue Aws::SNS::Errors::NotFound
        @sns_subscription.errors[:topic_arn] << 'is not found'
        @sns_topic_arns = fetch_sns_topic_arns
        render :new
      else
        @sns_subscription.save!
        update_sqs_policy!
        redirect_to @sns_subscription, notice: 'SNS subscription was successfully created.'
      end
    else
      render :new
    end
  end

  def update
    @sns_subscription = Barbeque::SNSSubscription.find(params[:id])
    if @sns_subscription.update(params.require(:sns_subscription).permit(:job_definition_id))
      redirect_to @sns_subscription, notice: 'SNS subscription was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @sns_subscription = Barbeque::SNSSubscription.find(params[:id])
    @sns_subscription.destroy
    update_sqs_policy!
    unsubscribe_topic!
    redirect_to sns_subscriptions_path, notice: 'SNS subscription was successfully destroyed.'
  end
  
  private

  def fetch_sns_topic_arns
    sns_client.list_topics.topics.map(&:topic_arn)
  end

  def update_sqs_policy!
    attrs = sqs_client.get_queue_attributes(
      queue_url: @sns_subscription.job_queue.queue_url,
      attribute_names: ['QueueArn'],
    )
    queue_arn = attrs.attributes['QueueArn']
    topic_arns = @sns_subscription.job_queue.sns_subscriptions.map(&:topic_arn)

    if topic_arns.present?
      policy = generate_policy(queue_arn: queue_arn, topic_arns: topic_arns)
    else
      policy = '' # Be blank when there're no subscriptions.
    end

    sqs_client.set_queue_attributes(
      queue_url: @sns_subscription.job_queue.queue_url,
      attributes: { 'Policy' => policy },
    )
  end

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

  def subscribe_topic!
    sns_client.subscribe(
      topic_arn: @sns_subscription.topic_arn,
      protocol: 'sqs',
      endpoint: queue_arn
    )
  end

  def unsubscribe_topic!
    sqs_attrs = sqs_client.get_queue_attributes(
      queue_url: @sns_subscription.job_queue.queue_url,
      attribute_names: ['QueueArn'],
    )
    queue_arn = sqs_attrs.attributes['QueueArn']

    subscriptions = sns_client.list_subscriptions_by_topic(
      topic_arn: @sns_subscription.topic_arn,
    )
    subscription_arn = subscriptions.subscriptions.find {|subscription| subscription.endpoint == queue_arn }.try!(:subscription_arn)

    if subscription_arn
      sns_client.unsubscribe(
        subscription_arn: subscription_arn,
      )
    end
  end

  def sqs_client
    @sqs_client ||= Aws::SQS::Client.new
  end

  def sns_client
    @sns_client ||= Aws::SNS::Client.new
  end

  def queue_arn
    return @queue_arn if @queue_arn

    sqs_attrs = sqs_client.get_queue_attributes(
      queue_url: @sns_subscription.job_queue.queue_url,
      attribute_names: ['QueueArn'],
    )
    @queue_arn = sqs_attrs.attributes['QueueArn']
  end
end
