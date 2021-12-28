require 'barbeque/config'
require 'barbeque/executor/docker'
require 'barbeque/executor/hako'

module Barbeque
  # Executor is responsible for starting executions and getting status of
  # executions.
  # Each executor must implement these methods.
  # - #initialize(options)
  #   - Create a executor with executor_options specified in config/barbeque.yml.
  # - #start_execution(job_execution, envs)
  #   - Start execution with environment variables. An executor must update the
  #     execution status from pending.
  # - #poll_execution(job_execution)
  #   - Get the execution status and update the job_execution columns.
  # - #start_retry(job_retry, envs)
  #   - Start retry with environment variables. An executor must update the
  #     retry status from pending and the corresponding execution status.
  # - #poll_retry(job_retry)
  #   - Get the execution status and update the job_retry and job_execution
  #     columns.

  module Executor
    def self.create
      klass = const_get(Barbeque.config.executor, false)
      klass.new(**Barbeque.config.executor_options)
    end
  end
end
