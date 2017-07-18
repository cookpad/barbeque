require 'barbeque/docker_image'
require 'barbeque/slack_notifier'
require 'open3'
require 'uri'

module Barbeque
  module Executor
    class Hako
      class HakoCommandError < StandardError
      end

      # @param [String] hako_dir
      # @param [Hash] hako_env
      # @param [String] yaml_dir
      def initialize(hako_dir:, hako_env: {}, yaml_dir:, oneshot_notification_prefix:)
        @hako_dir = hako_dir
        @hako_env = hako_env
        @yaml_dir = yaml_dir
        uri = URI.parse(oneshot_notification_prefix)
        @s3_bucket = uri.host
        @s3_prefix = uri.path.sub(%r{\A/}, '')
        @s3_region = URI.decode_www_form(uri.query || '').to_h['region']
      end

      # @param [Barbeque::JobExecution] job_execution
      # @param [Hash] envs
      def start_execution(job_execution, envs)
        docker_image = DockerImage.new(job_execution.job_definition.app.docker_image)
        cmd = build_hako_oneshot_command(docker_image, job_execution.job_definition.command, envs)
        stdout, stderr, status = Bundler.with_clean_env { Open3.capture3(@hako_env, *cmd, chdir: @hako_dir) }
        if status.success?
          job_execution.update!(status: :running)
          cluster, task_arn = extract_task_info(stdout)
          Barbeque::EcsHakoTask.create!(message_id: job_execution.message_id, cluster: cluster, task_arn: task_arn)
          Barbeque::ExecutionLog.save_stdout_and_stderr(job_execution, stdout, stderr)
        else
          job_execution.update!(status: :failed, finished_at: Time.zone.now)
          Barbeque::ExecutionLog.save_stdout_and_stderr(job_execution, stdout, stderr)
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
          job_execution.update!(status: :retried)
          job_retry.update!(status: :running)
          Barbeque::EcsHakoTask.create!(message_id: job_retry.message_id, cluster: cluster, task_arn: task_arn)
          Barbeque::ExecutionLog.save_stdout_and_stderr(job_retry, stdout, stderr)
        else
          job_retry.update!(status: :failed, finished_at: Time.zone.now)
          job_execution.update!(status: :failed)
          Barbeque::ExecutionLog.save_stdout_and_stderr(job_retry, stdout, stderr)
          Barbeque::SlackNotifier.notify_job_retry(job_retry)
        end
      end

      # @param [Barbeque::JobExecution] job_execution
      def poll_execution(job_execution)
        hako_task = Barbeque::EcsHakoTask.find_by!(message_id: job_execution.message_id)
        result = get_stopped_result(hako_task)
        if result
          detail = result.fetch('detail')
          task = Aws::Json::Parser.new(Aws::ECS::Client.api.operation('describe_tasks').output.shape.member(:tasks).shape.member).parse(JSON.dump(detail))
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
        result = get_stopped_result(hako_task)
        if result
          detail = result.fetch('detail')
          task = Aws::Json::Parser.new(Aws::ECS::Client.api.operation('describe_tasks').output.shape.member(:tasks).shape.member).parse(JSON.dump(detail))
          status = :failed
          task.containers.each do |container|
            if container.name == 'app'
              status = container.exit_code == 0 ? :success : :failed
            end
          end
          job_retry.update!(status: status, finished_at: task.stopped_at)
          job_execution.update!(status: status)
          Barbeque::SlackNotifier.notify_job_retry(job_retry)
        end
      end

      private

      def build_hako_oneshot_command(docker_image, command, envs)
        [
          'bundle', 'exec', 'hako', 'oneshot', '--no-wait', '--tag', docker_image.tag,
          *env_options(envs), File.join(@yaml_dir, "#{docker_image.repository}.yml"), '--', *command,
        ]
      end

      def env_options(envs)
        envs.map do |key, value|
          "--env=#{key}=#{value}"
        end
      end

      def s3_key_for_stopped_result(hako_task)
        "#{@s3_prefix}/#{hako_task.task_arn}/stopped.json"
      end

      def s3_client
        @s3_client ||= Aws::S3::Client.new(region: @s3_region, http_read_timeout: 5)
      end

      def get_stopped_result(hako_task)
        object = s3_client.get_object(bucket: @s3_bucket, key: s3_key_for_stopped_result(hako_task))
        JSON.parse(object.body.read)
      rescue Aws::S3::Errors::NoSuchKey
        nil
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
