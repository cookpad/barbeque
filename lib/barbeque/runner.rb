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
    DEFAULT_QUEUE = 'default'

    def initialize(queue_name: ENV['BARBEQUE_QUEUE'] || DEFAULT_QUEUE)
      @queue_name = queue_name
    end

    def run
      keep_maximum_concurrent_executions

      message = message_queue.dequeue
      return unless message

      handler = MessageHandler.const_get(message.type, false)
      handler.new(message: message, job_queue: message_queue.job_queue).run
    end

    def stop
      message_queue.stop!
    end

    private

    def message_queue
      @message_queue ||= MessageQueue.new(@queue_name)
    end

    def keep_maximum_concurrent_executions
      max_num = Barbeque.config.maximum_concurrent_executions
      unless max_num
        # nil means unlimited
        return
      end

      loop do
        current_num = Barbeque::JobExecution.where(status: [:running, :retried]).count
        if current_num < max_num
          return
        end
        sleep 10
      end
    end
  end
end
