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
    if Barbeque::SNSSubscriptionService.new.subscribe(@sns_subscription)
      redirect_to @sns_subscription, notice: 'SNS subscription was successfully created.'
    else
      @sns_topic_arns = fetch_sns_topic_arns
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
    sns_subscription = Barbeque::SNSSubscription.find(params[:id])
    Barbeque::SNSSubscriptionService.new.unsubscribe(sns_subscription)
    redirect_to sns_subscriptions_path, notice: 'SNS subscription was successfully destroyed.'
  end
  
  private

  def fetch_sns_topic_arns
    Barbeque::SNSSubscriptionService.sns_client.list_topics.flat_map(&:topics).map(&:topic_arn)
  end
end
