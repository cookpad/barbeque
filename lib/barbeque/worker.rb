require 'barbeque/message_handler'
require 'barbeque/message_queue'
require 'serverengine'

module Barbeque
  module Worker
    class UnexpectedMessageType < StandardError; end

    DEFAULT_QUEUE = 'default'

    def self.run
      options = {
        worker_type: 'process',
        workers:     (ENV['BARBEQUE_WORKER_NUM'] || 4).to_i,
        daemonize:   ENV['DAEMONIZE_BARBEQUE'] == '1',
        log:         Rails.env.production? ? Rails.root.join("log/barbeque_worker.log").to_s : $stdout,
        log_level:   Rails.env.production? ? :info : :debug,
        pid_path:    Rails.root.join('tmp/pids/barbeque_worker.pid').to_s,
        supervisor:  Rails.env.production?,
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
      # Use Raven.capture_exception
      Rails.logger.fatal("[ERROR] #{e.inspect}\n#{e.backtrace.join("\n")}")
    end

    private

    def message_queue
      @message_queue ||= MessageQueue.new(@queue_name)
    end
  end
end
