module Barbeque
  class ExecutionPoller
    def run
      Barbeque::JobExecution.running.find_in_batches do |job_executions|
        job_executions.shuffle.each do |job_execution|
          job_execution.with_lock do
            if job_execution.running?
              poll(job_execution)
            end
          end
        end
      end
      sleep 1
    end

    def stop
    end

    private

    def poll(job_execution)
      executor = Executor.create
      executor.poll_execution(job_execution)
    end
  end
end
