require 'aws-sdk'
require 'active_support'
require 'active_support/core_ext'

module Barbeque
  class ExecutionLog
    DEFAULT_S3_BUCKET_NAME = 'barbeque'

    class << self
      delegate :save, :load, to: :new
    end

    # @param [Barbeque::JobExecution,JobRetry] execution
    # @param [Hash] log
    def save(execution:, log:)
      s3.put_object(
        bucket: s3_bucket_name,
        key:    s3_key_for(execution: execution),
        body:   log.to_json,
      )
    end

    # @param [Barbeque::JobExecution,JobRetry] execution
    # @return [Hash] log
    def load(execution:)
      return {} if execution.pending?

      s3_object = s3.get_object(
        bucket: s3_bucket_name,
        key:    s3_key_for(execution: execution),
      )
      JSON.load(s3_object.body.read)
    end

    private

    def s3_bucket_name
      @s3_bucket_name ||= ENV['BARBEQUE_S3_BUCKET_NAME'] || DEFAULT_S3_BUCKET_NAME
    end

    # @param [Barbeque::JobExecution,JobRetry] execution
    # @param [String] message_id
    def s3_key_for(execution:)
      File.join(execution.app.name, execution.job_definition.job, execution.message_id)
    end

    def s3
      @s3 ||= Aws::S3::Client.new
    end
  end
end
