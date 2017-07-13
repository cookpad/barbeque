require 'barbeque/docker_image'
require 'barbeque/execution_log'
require 'barbeque/executor'
require 'barbeque/slack_notifier'

module Barbeque
  module MessageHandler
    class JobExecution
      # @param [Barbeque::Message::JobExecution] message
      # @param [Barbeque::JobQueue] job_queue
      def initialize(message:, job_queue:)
        @message = message
        @job_queue = job_queue
      end

      def run
        begin
          job_execution = Barbeque::JobExecution.create(message_id: @message.id, job_definition: job_definition, job_queue: @job_queue)
        rescue ActiveRecord::RecordNotUnique => e
          raise DuplicatedExecution.new(e.message)
        end
        job_execution.update!(status: :running)

        begin
          stdout, stderr, status = run_command
        rescue Exception => e
          job_execution.update!(status: :error, finished_at: Time.now)
          log_result(job_execution, '', '')
          Barbeque::SlackNotifier.notify_job_execution(job_execution)
          raise e
        end
        job_execution.update!(status: status.success? ? :success : :failed, finished_at: Time.now)
        Barbeque::SlackNotifier.notify_job_execution(job_execution)

        log_result(job_execution, stdout, stderr)
      end

      private

      def log_result(execution, stdout, stderr)
        Barbeque::ExecutionLog.save_message(execution, @message)  # TODO: Should be saved earlier
        Barbeque::ExecutionLog.save_stdout_and_stderr(execution, stdout, stderr)
      end

      # @return [String] stdout
      # @return [String] stderr
      # @return [Process::Status] status
      def run_command
        image  = DockerImage.new(job_definition.app.docker_image)
        executor = Executor.create(docker_image: image)
        executor.run(job_definition.command, job_envs)
      end

      def job_envs
        {
          'BARBEQUE_JOB'         => @message.job,
          'BARBEQUE_MESSAGE'     => @message.body.to_json,
          'BARBEQUE_MESSAGE_ID'  => @message.id,
          'BARBEQUE_QUEUE_NAME'  => @job_queue.name,
          'BARBEQUE_RETRY_COUNT' => '0',
        }
      end

      def job_definition
        @job_definition ||= Barbeque::JobDefinition.joins(:app).find_by!(
          job: @message.job,
          barbeque_apps: { name: @message.application },
        )
      end
    end
  end
end
