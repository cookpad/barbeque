require 'barbeque/exception_handler'
require 'barbeque/message_handler'
require 'barbeque/message_queue'
require 'serverengine'

module Barbeque
  module Worker
    class UnexpectedMessageType < StandardError; end

    DEFAULT_QUEUE = 'default'

    def self.run(
      worker_type: 'process',
      workers:     4,
      daemonize:   false,
      log:         $stdout,
      log_level:   :info,
      pid_path:    '/tmp/barbeque_worker.pid',
      supervisor:  true
    )
      options = {
        worker_type: worker_type,
        workers:     workers,
        daemonize:   daemonize,
        log:         log,
        log_level:   log_level,
        pid_path:    pid_path,
        supervisor:  supervisor,
      }

      worker = ServerEngine.create(nil, Barbeque::Worker, options)
      worker.run
    end

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

      handler = MessageHandler.const_get(message.type, false)
      handler.new(message: message, job_queue: message_queue.job_queue).run
    rescue => e
      Barbeque::ExceptionHandler.handle_exception(e)
    end

    private

    def message_queue
      @message_queue ||= MessageQueue.new(@queue_name)
    end
  end
end
