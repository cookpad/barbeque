require 'barbeque/maintenance'

class Barbeque::Api::JobExecutionsController < Barbeque::Api::ApplicationController
  include Garage::RestfulActions

  validates :create do
    string :application, required: true, description: 'Application name of the job'
    string :job, required: true, description: 'Class of Job to be enqueued'
    string :queue, required: true, description: 'Queue name to enqueue a job'
    any :message, required: true, description: 'Free-format JSON'
    integer :delay_seconds, description: 'Set message timer of SQS'
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
    @resource = Barbeque::Api::JobExecutionResource.new(model)
  rescue ActiveRecord::StatementInvalid, Mysql2::Error::ConnectionError => e
    if Barbeque::Maintenance.database_maintenance_mode?
      Barbeque::ExceptionHandler.handle_exception(e)
      @resource = Barbeque::Api::DatabaseMaintenanceResource.new(e)
    else
      raise e
    end
  end

  def create_resource
    message_id = enqueue_message
    model = Barbeque::JobExecution.new(message_id: message_id)
    @resource = Barbeque::Api::JobExecutionResource.new(model)
  end

  # @return [String] id of a message queued to SQS.
  def enqueue_message
    Barbeque::MessageEnqueuingService.new(
      application: params[:application],
      job:         params[:job],
      queue:       params[:queue],
      message:     params[:message],
      delay_seconds: params[:delay_seconds],
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

  def respond_with_resource_options
    if @resource.is_a?(Barbeque::Api::DatabaseMaintenanceResource)
      super.merge(status: 503)
    else
      super
    end
  end
end
