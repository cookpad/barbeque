require 'open3'

module Barbeque
  module Runner
    class Hako
      # @param [Barbeque::DockerImage] docker_image
      def initialize(docker_image:)
        @app_name = docker_image.repository
        @tag = docker_image.tag
      end

      # @param [Array<String>] command
      # @param [Hash] envs
      # @return [String] stdout
      # @return [String] stderr
      # @return [Process::Status] status
      def run(command, envs)
        cmd = build_hako_oneshot_command(command, envs)

        hako_dir  = ENV.fetch('HAKO_DIR')
        hako_envs = { 'GITHUB_ACCESS_TOKEN' => ENV['GITHUB_ACCESS_TOKEN'] }
        hako_envs.merge!('AWS_REGION' => ENV['AWS_REGION']) if ENV['AWS_REGION']
        Bundler.with_clean_env do
          Open3.capture3(hako_envs, *cmd, chdir: hako_dir)
        end
      end

      private

      def build_hako_oneshot_command(command, envs)
        [
          'bundle', 'exec', 'hako', 'oneshot', '--tag', @tag,
          *env_options(envs), "hako/#{@app_name}.yml", '--', *command,
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
