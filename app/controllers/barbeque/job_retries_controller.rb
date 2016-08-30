class Barbeque::JobRetriesController < Barbeque::ApplicationController
  def show
    @job_execution = Barbeque::JobExecution.find(params[:job_execution_id])
    @message = @job_execution.execution_log['message']

    @job_retry = JobRetry.find(params[:id])
    @stdout = @job_retry.execution_log['stdout']
    @stderr = @job_retry.execution_log['stderr']
  end
end
