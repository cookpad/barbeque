class Barbeque::JobQueuesController < Barbeque::ApplicationController
  def index
    @job_queues = Barbeque::JobQueue.all
  end

  def show
    @job_queue = Barbeque::JobQueue.find(params[:id])
  end

  def new
    @job_queue = Barbeque::JobQueue.new
  end

  def edit
    @job_queue = Barbeque::JobQueue.find(params[:id])
  end

  def create
    @job_queue = Barbeque::JobQueue.new(params.require(:job_queue).permit(:name, :description))
    @job_queue.queue_url = create_queue(@job_queue).queue_url if @job_queue.valid?

    if @job_queue.save
      redirect_to @job_queue, notice: 'Job queue was successfully created.'
    else
      render :new
    end
  end

  def update
    @job_queue = Barbeque::JobQueue.find(params[:id])
    # Name can't be changed after it's created.
    if @job_queue.update(params.require(:job_queue).permit(:description))
      redirect_to @job_queue, notice: 'Job queue was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @job_queue = Barbeque::JobQueue.find(params[:id])
    @job_queue.destroy
    redirect_to job_queues_url, notice: 'Job queue was successfully destroyed.'
  end

  private

  # @return [Aws::SQS::Types::CreateQueueResult] A struct which has only queue_url.
  def create_queue(job_queue)
    Aws::SQS::Client.new.create_queue(
      queue_name: job_queue.sqs_queue_name,
      attributes: {
        # All SQS queues' "ReceiveMessageWaitTimeSeconds" are configured to be 20s (maximum).
        # This should be as large as possible to reduce API-calling cost by long polling.
        # http://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_CreateQueue.html#API_CreateQueue_RequestParameters
        'ReceiveMessageWaitTimeSeconds' => Barbeque::JobQueue::SQS_RECEIVE_MESSAGE_WAIT_TIME.to_s,
      },
    )
  end
end
