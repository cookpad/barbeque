require 'barbeque/docker_image'
require 'barbeque/execution_log'
require 'barbeque/hako_s3_client'
require 'barbeque/slack_notifier'
require 'open3'

module Barbeque
  module Executor
    class Hako
      class HakoCommandError < StandardError
      end

      attr_reader :hako_s3_client

      # @param [String] hako_dir
      # @param [Hash] hako_env
      # @param [String] definition_dir
      # @param [String] yaml_dir (deprecated: renamed to definition_dir)
      def initialize(hako_dir:, hako_env: {}, yaml_dir: nil, definition_dir: nil, oneshot_notification_prefix:)
        @hako_dir = hako_dir
        @hako_env = hako_env
        @definition_dir =
          if definition_dir
            definition_dir
          elsif yaml_dir
            warn 'yaml_dir option is renamed to definition_dir. Please update config/barbeque.yml'
            yaml_dir
          else
            raise ArgumentError.new('definition_dir is required')
          end
        @hako_s3_client = HakoS3Client.new(oneshot_notification_prefix)
      end

      # @param [Barbeque::JobExecution] job_execution
      # @param [Hash] envs
      def start_execution(job_execution, envs)
        docker_image = DockerImage.new(job_execution.job_definition.app.docker_image)
        cmd = build_hako_oneshot_command(docker_image, job_execution.job_definition.command, envs)
        stdout, stderr, status = Bundler.with_clean_env { Open3.capture3(@hako_env, *cmd, chdir: @hako_dir) }
        if status.success?
          cluster, task_arn = extract_task_info(stdout)
          Barbeque::EcsHakoTask.create!(message_id: job_execution.message_id, cluster: cluster, task_arn: task_arn)
          Barbeque::ExecutionLog.try_save_stdout_and_stderr(job_execution, stdout, stderr)
          job_execution.update!(status: :running)
        else
          Barbeque::ExecutionLog.try_save_stdout_and_stderr(job_execution, stdout, stderr)
          job_execution.update!(status: :failed, finished_at: Time.zone.now)
          Barbeque::SlackNotifier.notify_job_execution(job_execution)
        end
      end

      # @param [Barbeque::JobRetry] job_retry
      # @param [Hash] envs
      def start_retry(job_retry, envs)
        job_execution = job_retry.job_execution
        docker_image = DockerImage.new(job_execution.job_definition.app.docker_image)
        cmd = build_hako_oneshot_command(docker_image, job_execution.job_definition.command, envs)
        stdout, stderr, status = Bundler.with_clean_env { Open3.capture3(@hako_env, *cmd, chdir: @hako_dir) }
        if status.success?
          cluster, task_arn = extract_task_info(stdout)
          Barbeque::EcsHakoTask.create!(message_id: job_retry.message_id, cluster: cluster, task_arn: task_arn)
          Barbeque::ExecutionLog.try_save_stdout_and_stderr(job_retry, stdout, stderr)
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
        end
      end

      # @param [Barbeque::JobExecution] job_execution
      def poll_execution(job_execution)
        hako_task = Barbeque::EcsHakoTask.find_by!(message_id: job_execution.message_id)
        task = @hako_s3_client.get_stopped_result(hako_task)
        if task
          status = :failed
          task.containers.each do |container|
            if container.name == 'app'
              status = container.exit_code == 0 ? :success : :failed
            end
          end
          job_execution.update!(status: status, finished_at: task.stopped_at)
          Barbeque::SlackNotifier.notify_job_execution(job_execution)
        end
      end

      # @param [Barbeque::JobRetry] job_execution
      def poll_retry(job_retry)
        hako_task = Barbeque::EcsHakoTask.find_by!(message_id: job_retry.message_id)
        job_execution = job_retry.job_execution
        task = @hako_s3_client.get_stopped_result(hako_task)
        if task
          status = :failed
          task.containers.each do |container|
            if container.name == 'app'
              status = container.exit_code == 0 ? :success : :failed
            end
          end
          Barbeque::ApplicationRecord.transaction do
            job_retry.update!(status: status, finished_at: task.stopped_at)
            job_execution.update!(status: status)
          end
          Barbeque::SlackNotifier.notify_job_retry(job_retry)
        end
      end

      private

      def build_hako_oneshot_command(docker_image, command, envs)
        [
          'bundle', 'exec', 'hako', 'oneshot', '--no-wait', '--tag', docker_image.tag,
          *env_options(envs), File.join(@definition_dir, "#{docker_image.repository}.yml"), '--', *command,
        ]
      end

      def env_options(envs)
        envs.map do |key, value|
          "--env=#{key}=#{value}"
        end
      end

      def extract_task_info(stdout)
        last_line = stdout.lines.last
        if last_line
          begin
            task_info = JSON.parse(last_line)
            cluster = task_info['cluster']
            task_arn = task_info['task_arn']
            if cluster && task_arn
              [cluster, task_arn]
            else
              raise HakoCommandError.new("Unable find cluster and task_arn in JSON: #{stdout}")
            end
          rescue JSON::ParserError => e
            raise HakoCommandError.new("Unable parse the last line as JSON: #{stdout}")
          end
        else
          raise HakoCommandError.new('stdout is empty')
        end
      end
    end
  end
end
