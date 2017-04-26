class Barbeque::SnsSubscriptionsController < Barbeque::ApplicationController
  def index
    @sns_subscriptions = Barbeque::SNSSubscription.all
  end

  def show
    @sns_subscription = Barbeque::SNSSubscription.find(params[:id])
  end

  def new
    @sns_subscription = Barbeque::SNSSubscription.new
  end

  def edit
    @sns_subscription = Barbeque::SNSSubscription.find(params[:id])
  end

  def create
    @sns_subscription = Barbeque::SNSSubscription.new(params.require(:sns_subscription).permit(:topic_arn, :job_queue_id, :job_definition_id))

    if @sns_subscription.save
      redirect_to @sns_subscription, notice: 'SNS subscription was successfully created.'
    else
      render :new
    end
  end

  def update
    @sns_subscription = Barbeque::SNSSubscription.find(params[:id])
    if @sns_subscription.update(params.require(:sns_subscription).permit(:job_queue_id, :job_definition_id))
      redirect_to @sns_subscription, notice: 'SNS subscription was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @sns_subscription = Barbeque::SNSSubscription.find(params[:id])
    @sns_subscription.destroy
    redirect_to sns_subscriptions_path, notice: 'SNS subscription was successfully destroyed.'
  end
end
