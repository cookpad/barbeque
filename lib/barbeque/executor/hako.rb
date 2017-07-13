require 'barbeque/docker_image'
require 'open3'

module Barbeque
  module Executor
    class Hako
      # @param [String] hako_dir
      # @param [Hash] hako_env
      # @param [String] yaml_dir
      def initialize(hako_dir:, hako_env: {}, yaml_dir:)
        @hako_dir = hako_dir
        @hako_env = hako_env
        @yaml_dir = yaml_dir
      end

      # @param [Barbeque::JobExecution] job_execution
      # @param [Hash] envs
      # @return [String] stdout
      # @return [String] stderr
      # @return [Process::Status] status
      def run(job_execution, envs)
        job_definition = job_execution.job_definition
        docker_image = DockerImage.new(job_definition.app.docker_image)
        cmd = build_hako_oneshot_command(docker_image, job_definition.command, envs)
        Bundler.with_clean_env do
          Open3.capture3(@hako_env, *cmd, chdir: @hako_dir)
        end
      end

      private

      def build_hako_oneshot_command(docker_image, command, envs)
        [
          'bundle', 'exec', 'hako', 'oneshot', '--tag', docker_image.tag,
          *env_options(envs), File.join(@yaml_dir, "#{docker_image.repository}.yml"), '--', *command,
        ]
      end

      def env_options(envs)
        envs.map do |key, value|
          "--env=#{key}=#{value}"
        end
      end
    end
  end
end
