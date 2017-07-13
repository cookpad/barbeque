require 'barbeque/docker_image'
require 'open3'

module Barbeque
  module Executor
    class Docker
      def initialize(_options)
      end

      # @param [Barbeque::JobExecution] job_execution
      # @param [Hash] envs
      # @return [String] stdout
      # @return [String] stderr
      # @return [Process::Status] status
      def run(job_execution, envs)
        job_definition = job_execution.job_definition
        docker_image = DockerImage.new(job_definition.app.docker_image)
        cmd = build_docker_run_command(docker_image, command, envs)
        Bundler.with_clean_env { Open3.capture3(*cmd) }
      end

      private

      def build_docker_run_command(docker_image, command, envs)
        ['docker', 'run', *env_options(envs), docker_image.to_s, *command]
      end

      def env_options(envs)
        envs.flat_map do |key, value|
          ['--env', "#{key}=#{value}"]
        end
      end
    end
  end
end
