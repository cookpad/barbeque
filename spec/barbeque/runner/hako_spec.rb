require 'barbeque/runner/hako'

describe Barbeque::Runner::Hako do
  let(:hako_directory) { '.' }
  let(:github_access_token) { 'access_token' }

  describe '#run' do
    let(:app_name) { 'dummy' }
    let(:tag) { 'latest' }
    let(:docker_image) { Barbeque::DockerImage.new("#{app_name}:#{tag}") }
    let(:job_command) { ['bundle', 'exec', 'barbeque:execute'] }
    let(:hako_env) { { 'AWS_REGION' => 'ap-northeast-1' } }
    let(:hako_command) do
      [
        'bundle', 'exec', 'hako', 'oneshot', '--tag', tag,
        '--env=FOO=BAR', "hako/#{app_name}.yml", '--', *job_command,
      ]
    end
    let(:envs) { { 'FOO' => 'BAR' } }

    it 'runs hako oneshot command within HAKO_DIR' do
      expect(Open3).to receive(:capture3).with(hako_env, *hako_command, chdir: hako_directory)
      Barbeque::Runner::Hako.new(
        docker_image: docker_image,
        hako_dir: hako_directory,
        hako_env: hako_env,
      ).run(job_command, envs)
    end
  end
end
