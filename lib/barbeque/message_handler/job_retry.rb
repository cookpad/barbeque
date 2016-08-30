require 'barbeque/docker_image'
require 'barbeque/execution_log'
require 'barbeque/runner'
require 'barbeque/slack_client'

module Barbeque
  module MessageHandler
    class JobRetry
      # @param [Barbeque::Message::JobExecution] message
      # @param [JobQueue] job_queue
      def initialize(message:, job_queue:)
        @message = message
        @job_queue = job_queue
      end

      def run
        job_retry = ::JobRetry.find_or_initialize_by(message_id: @message.id)
        job_retry.update!(job_execution: job_execution)
        job_execution.update!(status: 'retried')

        stdout, stderr, result = run_command
        status = result.success? ? :success : :failed
        job_retry.update!(status: status, finished_at: Time.now)
        job_execution.update!(status: status)
        notify_slack(job_retry, result)

        log_result(job_retry, stdout, stderr)
      end

      private

      def log_result(job_retry, stdout, stderr)
        log = { stdout: stdout, stderr: stderr }
        Barbeque::ExecutionLog.save(execution: job_retry, log: log)
      end

      # @param [JobRetry] job_retry
      # @param [Process::Status] result
      def notify_slack(job_retry, result)
        return if job_retry.slack_notification.nil?

        client = Barbeque::SlackClient.new(job_retry.slack_notification.channel)
        if result.success?
          if job_retry.slack_notification.notify_success
            client.notify_success("*[SUCCESS]* Succeeded to retry #{job_retry_link(job_retry)}")
          end
        else
          client.notify_failure(
            "*[FAILURE]* Failed to retry #{job_retry_link(job_retry)}" \
            " #{job_execution.slack_notification.failure_notification_text}"
          )
        end
      end

      def job_retry_link(job_retry)
        url = Barbeque::Engine.routes.url_helpers.job_execution_job_retry_url(
          job_retry.job_execution, job_retry, host: ENV['BARBEQUE_HOST']
        )
        "<#{url}|#{job_retry.job_definition.job}'s retry ##{job_retry.id}>"
      end

      def job_execution
        @job_execution ||= Barbeque::JobExecution.find_by!(message_id: @message.retry_message_id)
      end

      def run_command
        image  = DockerImage.new(job_execution.app.docker_image)
        runner = Runner.create(docker_image: image)
        runner.run(job_execution.job_definition.command, job_envs)
      end

      def job_envs
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
