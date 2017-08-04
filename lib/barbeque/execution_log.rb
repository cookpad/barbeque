require 'aws-sdk'
require 'active_support'
require 'active_support/core_ext'
require 'barbeque/exception_handler'

module Barbeque
  class ExecutionLog
    DEFAULT_S3_BUCKET_NAME = 'barbeque'

    class << self
      delegate :save_message, :save_stdout_and_stderr, :try_save_stdout_and_stderr, :load, to: :new

      def s3_client
        @s3_client ||= Aws::S3::Client.new
      end
    end

    # @param [Barbeque::JobExecution] execution
    # @param [Barbeque::Message::JobExecution] message
    def save_message(execution, message)
      put(execution, 'message.json', message.body.to_json)
    end

    # @param [Barbeque::JobExecution,Barbeque::JobRetry] execution
    # @param [String] stdout
    # @param [String] stderr
    def save_stdout_and_stderr(execution, stdout, stderr)
      put(execution, 'stdout.txt', stdout)
      put(execution, 'stderr.txt', stderr)
    end

    # @param [Barbeque::JobExecution,Barbeque::JobRetry] execution
    # @param [String] stdout
    # @param [String] stderr
    def try_save_stdout_and_stderr(execution, stdout, stderr)
      save_stdout_and_stderr(execution, stdout, stderr)
    rescue Aws::S3::Errors::ServiceError => e
      ExceptionHandler.handle_exception(e)
    end

    # @param [Barbeque::JobExecution,Barbeque::JobRetry] execution
    # @return [Hash] log
    def load(execution:)
      return {} if execution.pending?

      message = get(execution, 'message.json')
      stdout = get(execution, 'stdout.txt')
      stderr = get(execution, 'stderr.txt')
      if message || stdout || stderr
        {
          'message' => message,
          'stdout' => stdout,
          'stderr' => stderr,
        }
      else
        nil
      end
    end

    private

    def s3_bucket_name
      @s3_bucket_name ||= ENV['BARBEQUE_S3_BUCKET_NAME'] || DEFAULT_S3_BUCKET_NAME
    end

    # @param [Barbeque::JobExecution,Barbeque::JobRetry] execution
    # @param [String] filename
    def s3_key_for(execution, filename)
      "#{execution.app.name}/#{execution.job_definition.job}/#{execution.message_id}/#{filename}"
    end

    # @param [Barbeque::JobExecution,Barbeque::JobRetry] execution
    # @param [String] filename
    # @return [String]
    def get(execution, filename)
      s3_object = ExecutionLog.s3_client.get_object(
        bucket: s3_bucket_name,
        key: s3_key_for(execution, filename),
      )
      s3_object.body.read
    rescue Aws::S3::Errors::NoSuchKey
      nil
    end

    # @param [Barbeque::JobExecution,Barbeque::JobRetry] execution
    # @param [String] filename
    # @param [String] content
    def put(execution, filename, content)
      ExecutionLog.s3_client.put_object(
        bucket: s3_bucket_name,
        key: s3_key_for(execution, filename),
        body: content,
      )
    end
  end
end
