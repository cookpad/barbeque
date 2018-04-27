class Barbeque::Api::JobExecutionsController < Barbeque::Api::ApplicationController
  include Garage::RestfulActions

  validates :create do
    string :application, required: true, description: 'Application name of the job'
    string :job, required: true, description: 'Class of Job to be enqueued'
    string :queue, required: true, description: 'Queue name to enqueue a job'
    any :message, required: true, description: 'Free-format JSON'
  end

  rescue_from Barbeque::MessageEnqueuingService::BadRequest do |exc|
    render status: 400, json: { error: exc.message }
  end

  private

  def require_resources
    protect_resource_as Barbeque::Api::JobExecutionResource
  end

  def require_resource
    model = Barbeque::JobExecution.find_or_initialize_by(message_id: params[:message_id])
    @resource = Barbeque::Api::JobExecutionResource.new(model, url_options)
  end

  def create_resource
    message_id = enqueue_message
    model = Barbeque::JobExecution.new(message_id: message_id)
    @resource = Barbeque::Api::JobExecutionResource.new(model, url_options)
  end

  # @return [String] id of a message queued to SQS.
  def enqueue_message
    Barbeque::MessageEnqueuingService.new(
      application: params[:application],
      job:         params[:job],
      queue:       params[:queue],
      message:     params[:message],
    ).run
  end

  # Link to job_execution isn't available if it isn't dequeued yet
  def location
    if @resource.id
      super
    else
      nil
    end
  end
end
