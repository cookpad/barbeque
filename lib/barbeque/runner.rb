require 'barbeque/exception_handler'
require 'barbeque/execution_log'
require 'barbeque/message_handler'
require 'barbeque/message_queue'

module Barbeque
  class Runner
    DEFAULT_QUEUE = 'default'

    def initialize(queue_name: ENV['BARBEQUE_QUEUE'] || DEFAULT_QUEUE)
      @queue_name = queue_name
    end

    def run
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
  end
end
