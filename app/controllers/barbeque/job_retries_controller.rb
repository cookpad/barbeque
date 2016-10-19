class Barbeque::JobRetriesController < Barbeque::ApplicationController
  def show
    @job_execution = Barbeque::JobExecution.find(params[:job_execution_id])
    begin
      @execution_log = @job_execution.execution_log
    rescue Aws::S3::Errors::NoSuchKey
      @execution_log = nil
    end

    @job_retry = Barbeque::JobRetry.find(params[:id])
    begin
      @retry_log = @job_retry.execution_log
    rescue Aws::S3::Errors::NoSuchKey
      @retry_log = nil
    end
  end
end
