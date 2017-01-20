require 'open3'

module Barbeque
  module Runner
    class Hako
      # @param [Barbeque::DockerImage] docker_image
      # @param [String] hako_dir
      # @param [Hash] hako_env
      # @param [String] yaml_dir
      def initialize(docker_image:, hako_dir:, hako_env: {}, yaml_dir:)
        @app_name = docker_image.repository
        @tag      = docker_image.tag
        @hako_dir = hako_dir
        @hako_env = hako_env
        @yaml_dir = yaml_dir
      end

      # @param [Array<String>] command
      # @param [Hash] envs
      # @return [String] stdout
      # @return [String] stderr
      # @return [Process::Status] status
      def run(command, envs)
        cmd = build_hako_oneshot_command(command, envs)
        Bundler.with_clean_env do
          Open3.capture3(@hako_env, *cmd, chdir: @hako_dir)
        end
      end

      private

      def build_hako_oneshot_command(command, envs)
        [
          'bundle', 'exec', 'hako', 'oneshot', '--tag', @tag,
          *env_options(envs), File.join(@yaml_dir, "#{@app_name}.yml"), '--', *command,
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
