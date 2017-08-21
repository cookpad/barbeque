require 'barbeque/config'

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

  def sqs_attributes
    job_queue = Barbeque::JobQueue.find(params[:id])
    attributes = self.class.sqs_client.get_queue_attributes(
      queue_url: job_queue.queue_url,
      attribute_names: %w[
        ApproximateNumberOfMessages
        ApproximateNumberOfMessagesNotVisible
        RedrivePolicy
        QueueArn
      ],
    ).attributes
    dlq_metrics =
      if attributes['RedrivePolicy']
        dlq_arn = JSON.parse(attributes['RedrivePolicy']).fetch('deadLetterTargetArn')
        dlq_name = queue_name_from_arn(dlq_arn)
        dlq_url = self.class.sqs_client.get_queue_url(queue_name: dlq_name).queue_url
        dlq_attributes = self.class.sqs_client.get_queue_attributes(
          queue_url: dlq_url,
          attribute_names: %w[
            ApproximateNumberOfMessages
            ApproximateNumberOfMessagesNotVisible
          ],
        ).attributes.transform_values(&:to_i)
        {
          queue_name: dlq_name,
          attributes: dlq_attributes,
        }
      else
        nil
      end
    render json: {
      queue_name: queue_name_from_arn(attributes['QueueArn']),
      attributes: {
        'ApproximateNumberOfMessages' => attributes['ApproximateNumberOfMessages'].to_i,
        'ApproximateNumberOfMessagesNotVisible' => attributes['ApproximateNumberOfMessagesNotVisible'].to_i,
      },
      dlq: dlq_metrics,
    }
  end

  def sqs_metrics
    queue_name = params[:queue_name]
    unless queue_name.present?
      render status: 400, json: { error: 'params[:queue_name] is required' }
      return
    end
    metric_name = params[:metric_name]
    unless metric_name.present?
      render status: 400, json: { error: 'params[:metric_name] is required' }
      return
    end
    statistic = params[:statistic]
    unless statistic.present?
      render status: 400, json: { error: 'params[:statistic] is required' }
      return
    end

    now = Time.zone.now
    from = now - 24.hours
    resp = self.class.cloudwatch_client.get_metric_statistics(
      namespace: 'AWS/SQS',
      metric_name: metric_name,
      dimensions: [
        { name: 'QueueName', value: queue_name },
      ],
      start_time: from,
      end_time: now,
      period: compute_minimum_period(from, now),
      statistics: [statistic],
    )

    render json: {
      label: resp.label,
      datapoints: resp.datapoints.sort_by(&:timestamp).map { |datapoint|
        {
          timestamp: Time.zone.at(datapoint.timestamp),
          value: datapoint[statistic.underscore],
        }
      },
    }
  end

  private

  # @return [Aws::SQS::Types::CreateQueueResult] A struct which has only queue_url.
  def create_queue(job_queue)
    Aws::SQS::Client.new.create_queue(
      queue_name: job_queue.sqs_queue_name,
      attributes: {
        'ReceiveMessageWaitTimeSeconds' => Barbeque.config.sqs_receive_message_wait_time.to_s,
      },
    )
  end

  def self.sqs_client
    @sqs_client ||= Aws::SQS::Client.new
  end

  def self.cloudwatch_client
    @cloudwatch_client ||= Aws::CloudWatch::Client.new
  end

  def queue_name_from_arn(arn)
    arn.slice(/[^:]+\z/)
  end

  def compute_minimum_period(start_time, end_time, maximum_datapoint: 1440)
    # - Datapoints cannot exceed 1,440
    # - Period must be a multiple of 60
    maximum_datapoint = [maximum_datapoint, 1440].min.to_f
    minimum_period = ((end_time - start_time) / maximum_datapoint).ceil
    r = minimum_period % 60
    if r == 0
      minimum_period
    else
      minimum_period - r + 60
    end
  end
end
