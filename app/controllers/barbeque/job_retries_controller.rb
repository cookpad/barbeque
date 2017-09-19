class Barbeque::JobRetriesController < Barbeque::ApplicationController
  def show
    @job_execution = Barbeque::JobExecution.find_by!(message_id: params[:job_execution_message_id])
    @execution_log = @job_execution.execution_log

    @job_retry = Barbeque::JobRetry.find(params[:id])
    @retry_log = @job_retry.execution_log
  end
end
