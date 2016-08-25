require 'barbeque/message_handler'
require 'job_executor/message_queue'
require 'execution_log'

module JobExecutor
  module Worker
    class UnexpectedMessageType < StandardError; end

    DEFAULT_QUEUE = 'default'

    def initialize
      @queue_name = ENV['BARBEQUE_QUEUE'] || DEFAULT_QUEUE
    end

    def run
      until @stop
        execute_job
      end
    end

    def stop
      @stop = true
      message_queue.stop!
    end

    def execute_job
      message = message_queue.dequeue
      return unless message

      handler = Barbeque::MessageHandler.const_get(message.type, false)
      handler.new(message: message, job_queue: message_queue.job_queue).run
    rescue => e
      # Use Raven.capture_exception
      Rails.logger.fatal("[ERROR] #{e.inspect}\n#{e.backtrace.join("\n")}")
    end

    private

    def message_queue
      @message_queue ||= MessageQueue.new(@queue_name)
    end
  end
end
