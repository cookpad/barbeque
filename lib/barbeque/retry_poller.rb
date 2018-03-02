require 'barbeque/exception_handler'
require 'barbeque/executor'

module Barbeque
  class RetryPoller
    def initialize(job_queue)
      @job_queue      = job_queue
      @stop_requested = false
    end

    def run
      Barbeque::JobRetry
        .joins(:job_execution)
        .running
        .merge(Barbeque::JobExecution.where(job_queue: @job_queue))
        .find_in_batches do |job_retries|
        job_retries.shuffle.each do |job_retry|
          if @stop_requested
            return
          end
          job_retry.with_lock do
            if job_retry.running?
              poll(job_retry)
            end
          end
        end
      end
      sleep 1
    end

    def stop
      @stop_requested = true
    end

    private

    def poll(job_retry)
      Barbeque::ExceptionHandler.set_message_context(job_retry.message_id, nil)
      executor = Executor.create
      executor.poll_retry(job_retry)
    end
  end
end
