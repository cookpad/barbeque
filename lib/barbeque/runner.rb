require 'barbeque/config'
require 'barbeque/exception_handler'
require 'barbeque/execution_log'
require 'barbeque/message_handler'
require 'barbeque/message_queue'

module Barbeque
  # Part of barbeque-worker.
  # Runner dequeues a message from {MessageQueue} (Amazon SQS) and dispatches
  # it to message handler.

  class Runner
    def initialize(job_queue)
      @job_queue = job_queue
    end

    def run
      keep_maximum_concurrent_executions

      message = message_queue.dequeue
      return unless message

      Barbeque::ExceptionHandler.set_message_context(message.id, message.type)
      handler = MessageHandler.const_get(message.type, false)
      handler.new(message: message, message_queue: message_queue).run
    end

    def stop
      message_queue.stop!
    end

    private

    def message_queue
      @message_queue ||= MessageQueue.new(@job_queue)
    end

    def keep_maximum_concurrent_executions
      max_num = Barbeque.config.maximum_concurrent_executions
      unless max_num
        # nil means unlimited
        return
      end

      loop do
        current_num = @job_queue.job_executions.where(status: [:running, :retried]).count
        if current_num < max_num
          return
        end
        interval = Barbeque.config.runner_wait_seconds
        Rails.logger.info("#{current_num} executions are running but maximum_concurrent_executions is configured to #{max_num}. Waiting #{interval} seconds...")
        sleep(interval)
      end
    end
  end
end
