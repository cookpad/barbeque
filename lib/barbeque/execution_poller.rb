require 'barbeque/exception_handler'
require 'barbeque/executor'

module Barbeque
  class ExecutionPoller
    def initialize(job_queue)
      @job_queue      = job_queue
      @stop_requested = false
    end

    def run
      @job_queue.job_executions.running.find_in_batches do |job_executions|
        job_executions.shuffle.each do |job_execution|
          if @stop_requested
            return
          end
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
      @stop_requested = true
    end

    private

    def poll(job_execution)
      Barbeque::ExceptionHandler.set_message_context(job_execution.message_id, nil)
      executor = Executor.create
      executor.poll_execution(job_execution)
    end
  end
end
