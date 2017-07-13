require 'barbeque/execution_log'
require 'barbeque/executor'
require 'barbeque/slack_notifier'

module Barbeque
  module MessageHandler
    class MessageNotFound < StandardError; end

    class JobRetry
      # @param [Barbeque::Message::JobExecution] message
      # @param [Barbeque::JobQueue] job_queue
      def initialize(message:, job_queue:)
        @message = message
        @job_queue = job_queue
      end

      def run
        begin
          job_retry = Barbeque::JobRetry.create(message_id: @message.id, job_execution: job_execution)
        rescue ActiveRecord::RecordNotUnique => e
          raise DuplicatedExecution.new(e.message)
        end
        job_execution.update!(status: :retried)
        job_retry.update!(status: :running)

        begin
          stdout, stderr, result = Executor.create.run(job_retry.job_execution, job_envs)
        rescue Exception => e
          job_retry.update!(status: :error, finished_at: Time.now)
          job_execution.update!(status: :error)
          Barbeque::ExecutionLog.save_stdout_and_stderr(job_retry, '', "#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
          Barbeque::SlackNotifier.notify_job_retry(job_retry)
          raise e
        end
        status = result.success? ? :success : :failed
        job_retry.update!(status: status, finished_at: Time.now)
        job_execution.update!(status: status)
        Barbeque::ExecutionLog.save_stdout_and_stderr(job_retry, stdout, stderr)
        Barbeque::SlackNotifier.notify_job_retry(job_retry)
      end

      private

      def job_execution
        @job_execution ||= Barbeque::JobExecution.find_by!(message_id: @message.retry_message_id)
      end

      def job_envs
        if job_execution.execution_log.nil?
          raise MessageNotFound.new('failed to fetch retried message')
        end

        {
          'BARBEQUE_JOB'         => job_execution.job_definition.job,
          'BARBEQUE_MESSAGE'     => job_execution.execution_log['message'],
          'BARBEQUE_MESSAGE_ID'  => @message.retry_message_id,
          'BARBEQUE_QUEUE_NAME'  => @job_queue.name,
          'BARBEQUE_RETRY_COUNT' => job_execution.job_retries.count.to_s,
        }
      end
    end
  end
end
