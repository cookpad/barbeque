module Barbeque
  class RetryPoller
    def run
      Barbeque::JobRetry.running.find_in_batches do |job_retries|
        job_retries.shuffle.each do |job_retry|
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
    end

    private

    def poll(job_retry)
      executor = Executor.create
      executor.poll_retry(job_retry)
    end
  end
end
