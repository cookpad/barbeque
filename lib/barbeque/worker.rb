require 'barbeque/exception_handler'
require 'barbeque/execution_poller'
require 'barbeque/retry_poller'
require 'barbeque/runner'
require 'serverengine'

module Barbeque
  module Worker
    DEFAULT_QUEUE = ENV['BARBEQUE_DEFAULT_QUEUE'] || 'default'

    class UnexpectedMessageType < StandardError; end

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
      queue_name = ENV['BARBEQUE_QUEUE'] || DEFAULT_QUEUE
      queue      = Barbeque::JobQueue.find_by!(name: queue_name)

      @command =
        case worker_id
        when 0
          ExecutionPoller.new(queue)
        when 1
          RetryPoller.new(queue)
        else
          Runner.new(queue)
        end
    end

    def run
      $0 = "barbeque-worker (worker_id=#{worker_id} command=#{@command.class.name})"
      until @stop
        begin
          execute_command
        rescue => e
          Barbeque::ExceptionHandler.handle_exception(e)
        end
        Barbeque::ExceptionHandler.clear_context
      end
    end

    def stop
      @stop = true
      @command.stop
    end

    def execute_command
      @command.run
    end
  end
end
