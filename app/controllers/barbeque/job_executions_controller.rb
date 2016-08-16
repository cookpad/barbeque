class Barbeque::JobExecutionsController < Barbeque::ApplicationController
  def show
    @job_execution = JobExecution.find(params[:id])
    log = @job_execution.execution_log
    @message = log['message']
    @stdout  = log['stdout']
    @stderr  = log['stderr']
  end

  def retry
    @job_execution = JobExecution.find(params[:job_execution_id])
    raise ActionController::BadRequest unless @job_execution.failed?

    result = Barbeque::MessageRetryingService.new(message_id: @job_execution.message_id).run
    @job_execution.retried!

    redirect_to @job_execution, notice: "Succeed to retry (message_id=#{result.message_id})"
  end
end
