class Barbeque::JobRetriesController < Barbeque::ApplicationController
  def show
    @job_retry = Barbeque::JobRetry.find(params[:id])
    @job_execution = @job_retry.job_execution

    if params[:job_execution_message_id] != @job_execution.message_id
      redirect_to([@job_execution, @job_retry])
    end

    @execution_log = @job_execution.execution_log
    @retry_log = @job_retry.execution_log
  end
end
