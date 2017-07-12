require 'barbeque/slack_client'

module Barbeque
  class SlackNotifier
    # @param [Barbeque::JobExecution] job_execution
    def notify_job_execution(job_execution)
      return if job_execution.slack_notification.nil?

      client = Barbeque::SlackClient.new(job_execution.slack_notification.channel)
      if job_execution.success?
        if job_execution.slack_notification.notify_success
          client.notify_success("*[SUCCESS]* Succeeded to execute #{job_execution_link(job_execution)}")
        end
      elsif job_execution.failed?
        client.notify_failure(
          "*[FAILURE]* Failed to execute #{job_execution_link(job_execution)}" \
          " #{job_execution.slack_notification.failure_notification_text}"
        )
      else
        client.notify_failure(
          "*[ERROR]* Failed to execute #{job_execution_link(job_execution)}" \
          " #{job_execution.slack_notification.failure_notification_text}"
        )
      end
    end

    # @param [Barbeque::JobRetry] job_retry
    def notify_job_retry(job_retry)
      return if job_retry.slack_notification.nil?

      client = Barbeque::SlackClient.new(job_retry.slack_notification.channel)
      if job_retry.success?
        if job_retry.slack_notification.notify_success
          client.notify_success("*[SUCCESS]* Succeeded to retry #{job_retry_link(job_retry)}")
        end
      elsif job_retry.failed?
        client.notify_failure(
          "*[FAILURE]* Failed to retry #{job_retry_link(job_retry)}" \
          " #{job_retry.slack_notification.failure_notification_text}"
        )
      else
        client.notify_failure(
          "*[ERROR]* Failed to retry #{job_retry_link(job_retry)}" \
          " #{job_retry.slack_notification.failure_notification_text}"
        )
      end
    end

    private

    def barbeque_host
      ENV['BARBEQUE_HOST']
    end

    def job_execution_link(job_execution)
      "<#{job_execution_url(job_execution)}|#{job_execution.job_definition.job} ##{job_execution.id}>"
    end

    def job_execution_url(job_execution)
      Barbeque::Engine.routes.url_helpers.job_execution_url(job_execution, host: barbeque_host)
    end

    def job_retry_link(job_retry)
      "<#{job_retry_url(job_retry)}|#{job_retry.job_definition.job}'s retry ##{job_retry.id}>"
    end

    def job_retry_url(job_retry)
      Barbeque::Engine.routes.url_helpers.job_execution_job_retry_url(job_retry.job_execution, job_retry, host: barbeque_host)
    end
  end
end
