class Barbeque::JobExecutionsController < Barbeque::ApplicationController
  ID_REGEXP = /\A[0-9]+\z/

  def show
    if ID_REGEXP === params[:message_id]
      job_execution = Barbeque::JobExecution.find_by(id: params[:message_id])
      if job_execution
        redirect_to(job_execution)
        return
      end
    end
    @job_execution = Barbeque::JobExecution.find_by!(message_id: params[:message_id])
    # Return 404 when job_definition or app is deleted
    @job_definition = Barbeque::JobDefinition.find(@job_execution.job_definition_id)
    @app = Barbeque::App.find(@job_definition.app_id)
    @log = @job_execution.execution_log
    @job_retries = @job_execution.job_retries.order(id: :desc)
  end

  def retry
    @job_execution = Barbeque::JobExecution.find_by!(message_id: params[:job_execution_message_id])
    raise ActionController::BadRequest unless @job_execution.retryable?

    result = Barbeque::MessageRetryingService.new(message_id: @job_execution.message_id).run
    @job_execution.retried!

    redirect_to @job_execution, notice: "Succeed to retry (message_id=#{result.message_id})"
  end
end
