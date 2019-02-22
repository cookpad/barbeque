require 'barbeque/docker_image'
require 'barbeque/execution_log'
require 'barbeque/slack_notifier'
require 'open3'

module Barbeque
  module Executor
    class Docker
      class DockerCommandError < StandardError
      end

      def initialize(_options)
      end

      # @param [Barbeque::JobExecution] job_execution
      # @param [Hash] envs
      def start_execution(job_execution, envs)
        docker_image = DockerImage.new(job_execution.job_definition.app.docker_image)
        cmd = build_docker_run_command(docker_image, job_execution.job_definition.command, envs)
        stdout, stderr, status = Open3.capture3(*cmd)
        if status.success?
          Barbeque::DockerContainer.create!(message_id: job_execution.message_id, container_id: stdout.chomp)
          job_execution.update!(status: :running)
        else
          Barbeque::ExecutionLog.try_save_stdout_and_stderr(job_execution, stdout, stderr)
          job_execution.update!(status: :failed, finished_at: Time.zone.now)
          Barbeque::SlackNotifier.notify_job_execution(job_execution)
          job_execution.retry_if_possible!
        end
      end

      # @param [Barbeque::JobRetry] job_retry
      # @param [Hash] envs
      def start_retry(job_retry, envs)
        job_execution = job_retry.job_execution
        docker_image = DockerImage.new(job_execution.job_definition.app.docker_image)
        cmd = build_docker_run_command(docker_image, job_execution.job_definition.command, envs)
        stdout, stderr, status = Open3.capture3(*cmd)
        if status.success?
          Barbeque::DockerContainer.create!(message_id: job_retry.message_id, container_id: stdout.chomp)
          Barbeque::ApplicationRecord.transaction do
            job_execution.update!(status: :retried)
            job_retry.update!(status: :running)
          end
        else
          Barbeque::ExecutionLog.try_save_stdout_and_stderr(job_retry, stdout, stderr)
          Barbeque::ApplicationRecord.transaction do
            job_retry.update!(status: :failed, finished_at: Time.zone.now)
            job_execution.update!(status: :failed)
          end
          Barbeque::SlackNotifier.notify_job_retry(job_retry)
          job_execution.retry_if_possible!
        end
      end

      # @param [Barbeque::JobExecution] job_execution
      def poll_execution(job_execution)
        container = Barbeque::DockerContainer.find_by!(message_id: job_execution.message_id)
        info = inspect_container(container.container_id)
        if info['State'] && info['State']['Status'] != 'running'
          finished_at = Time.zone.parse(info['State']['FinishedAt'])
          exit_code = info['State']['ExitCode']
          job_execution.update!(status: exit_code == 0 ? :success : :failed, finished_at: finished_at)

          stdout, stderr = get_logs(container.container_id)
          Barbeque::ExecutionLog.save_stdout_and_stderr(job_execution, stdout, stderr)
          Barbeque::SlackNotifier.notify_job_execution(job_execution)
          if exit_code != 0
            job_execution.retry_if_possible!
          end
        end
      end

      # @param [Barbeque::JobRetry] job_retry
      def poll_retry(job_retry)
        container = Barbeque::DockerContainer.find_by!(message_id: job_retry.message_id)
        job_execution = job_retry.job_execution
        info = inspect_container(container.container_id)
        if info['State'] && info['State']['Status'] != 'running'
          finished_at = Time.zone.parse(info['State']['FinishedAt'])
          exit_code = info['State']['ExitCode']
          status = exit_code == 0 ? :success : :failed
          Barbeque::ApplicationRecord.transaction do
            job_retry.update!(status: status, finished_at: finished_at)
            job_execution.update!(status: status)
          end

          stdout, stderr = get_logs(container.container_id)
          Barbeque::ExecutionLog.save_stdout_and_stderr(job_retry, stdout, stderr)
          Barbeque::SlackNotifier.notify_job_retry(job_retry)
          if status == :failed
            job_execution.retry_if_possible!
          end
        end
      end

      private

      # @param [Barbeque::DockerImage] docker_image
      # @param [Array<String>] command
      # @param [Hash] envs
      def build_docker_run_command(docker_image, command, envs)
        ['docker', 'run', '--detach', *env_options(envs), docker_image.to_s, *command]
      end

      def env_options(envs)
        envs.flat_map do |key, value|
          ['--env', "#{key}=#{value}"]
        end
      end

      # @param [String] container_id
      # @return [Hash] container info
      def inspect_container(container_id)
        stdout, stderr, status = Open3.capture3('docker', 'inspect', container_id)
        if status.success?
          begin
            JSON.parse(stdout)[0]
          rescue JSON::ParserError => e
            raise DockerCommandError.new("Unable to parse JSON: #{e.class}: #{e.message}: #{stdout}")
          end
        else
          raise DockerCommandError.new("Unable to inspect Docker container #{container.container_id}: STDOUT: #{stdout}; STDERR: #{stderr}")
        end
      end

      # @param [String] container_id
      # @return [String] stdout
      # @return [String] stderr
      def get_logs(container_id)
        stdout, stderr, status = Open3.capture3('docker', 'logs', container_id)
        if status.success?
          [stdout, stderr]
        else
          raise DockerCommandError.new("Unable to get Docker container logs #{container.container_id}: STDOUT: #{stdout}; STDERR: #{stderr}")
        end
      end
    end
  end
end
