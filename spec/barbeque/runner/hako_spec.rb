require 'barbeque/runner/hako'

describe Barbeque::Runner::Hako do
  let(:hako_directory) { '.' }
  let(:github_access_token) { 'access_token' }

  around do |example|
    original_env = ENV.to_h.dup
    ENV['HAKO_DIR'] = hako_directory
    ENV['GITHUB_ACCESS_TOKEN'] = github_access_token
    ENV['AWS_REGION'] = 'ap-northeast-1'
    example.run
    ENV.replace(original_env)
  end

  describe '#run' do
    let(:app_name) { 'dummy' }
    let(:tag) { 'latest' }
    let(:docker_image) { Barbeque::DockerImage.new("#{app_name}:#{tag}") }
    let(:job_command) { ['bundle', 'exec', 'barbeque:execute'] }
    let(:hako_command) do
      [
        'bundle', 'exec', 'hako', 'oneshot', '--tag', tag,
        '--env=FOO=BAR', "hako/#{app_name}.yml", '--', *job_command,
      ]
    end
    let(:envs) { { 'FOO' => 'BAR' } }

    it 'runs hako oneshot command within HAKO_DIR' do
      expect(Open3).to receive(:capture3).with(
        { 'GITHUB_ACCESS_TOKEN' => github_access_token, 'AWS_REGION' => 'ap-northeast-1' },
        *hako_command,
        chdir: hako_directory,
      )
      Barbeque::Runner::Hako.new(docker_image: docker_image).run(job_command, envs)
    end
  end
end
