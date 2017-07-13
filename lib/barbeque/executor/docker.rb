require 'open3'

module Barbeque
  module Executor
    class Docker
      # @param [Barbeque::DockerImage] docker_image
      def initialize(docker_image:)
        @docker_image = docker_image.to_s
      end

      # @param [Array<String>] command
      # @param [Hash] envs
      # @return [String] stdout
      # @return [String] stderr
      # @return [Process::Status] status
      def run(command, envs)
        cmd = build_docker_run_command(command, envs)
        Bundler.with_clean_env { Open3.capture3(*cmd) }
      end

      private

      def build_docker_run_command(command, envs)
        ['docker', 'run', *env_options(envs), @docker_image, *command]
      end

      def env_options(envs)
        envs.flat_map do |key, value|
          ['--env', "#{key}=#{value}"]
        end
      end
    end
  end
end
