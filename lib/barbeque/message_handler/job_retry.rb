require 'barbeque/execution_log'
require 'barbeque/executor'
require 'barbeque/slack_notifier'

module Barbeque
  module MessageHandler
    class MessageNotFound < StandardError; end

    class JobRetry
      # @param [Barbeque::Message::JobExecution] message
      # @param [Barbeque::MessageQueue] message_queue
      def initialize(message:, message_queue:)
        @message = message
        @message_queue = message_queue
      end

      def run
        job_retry = create_job_retry

        begin
          Executor.create.start_retry(job_retry, job_envs)
        rescue Exception => e
          job_retry.update!(status: :error, finished_at: Time.now)
          job_execution.update!(status: :error)
          Barbeque::ExecutionLog.save_stdout_and_stderr(job_retry, '', "#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
          Barbeque::SlackNotifier.notify_job_retry(job_retry)
          raise e
        end
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
          'BARBEQUE_QUEUE_NAME'  => @message_queue.job_queue.name,
          'BARBEQUE_RETRY_COUNT' => job_execution.job_retries.count.to_s,
          'BARBEQUE_SENT_TIMESTAMP' => @message.sent_timestamp,
        }
      end

      def create_job_retry
        Barbeque::JobRetry.transaction do
          Barbeque::JobRetry.create(message_id: @message.id, job_execution: job_execution).tap do
            @message_queue.delete_message(@message)
          end
        end
      rescue ActiveRecord::RecordNotUnique => e
        raise DuplicatedExecution.new(e.message)
      end
    end
  end
end
