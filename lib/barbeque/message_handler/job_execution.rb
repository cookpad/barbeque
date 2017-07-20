require 'barbeque/execution_log'
require 'barbeque/executor'
require 'barbeque/slack_notifier'

module Barbeque
  module MessageHandler
    class JobExecution
      # @param [Barbeque::Message::JobExecution] message
      # @param [Barbeque::MessageQueue] message_queue
      def initialize(message:, message_queue:)
        @message = message
        @message_queue = message_queue
      end

      def run
        begin
          job_execution = Barbeque::JobExecution.create(message_id: @message.id, job_definition: job_definition, job_queue: @message_queue.job_queue)
        rescue ActiveRecord::RecordNotUnique => e
          @message_queue.delete_message(@message)
          raise DuplicatedExecution.new(e.message)
        end
        Barbeque::ExecutionLog.save_message(job_execution, @message)
        @message_queue.delete_message(@message)

        begin
          Executor.create.start_execution(job_execution, job_envs)
        rescue Exception => e
          job_execution.update!(status: :error, finished_at: Time.now)
          Barbeque::ExecutionLog.save_stdout_and_stderr(job_execution, '', "#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
          Barbeque::SlackNotifier.notify_job_execution(job_execution)
          raise e
        end
      end

      private

      def job_envs
        {
          'BARBEQUE_JOB'         => @message.job,
          'BARBEQUE_MESSAGE'     => @message.body.to_json,
          'BARBEQUE_MESSAGE_ID'  => @message.id,
          'BARBEQUE_QUEUE_NAME'  => @message_queue.job_queue.name,
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
