require 'rails_helper'
require 'barbeque/executor/hako'

describe Barbeque::Executor::Hako do
  let(:hako_directory) { '.' }
  let(:github_access_token) { 'access_token' }

  describe '#run' do
    let(:app_name) { 'dummy' }
    let(:tag) { 'latest' }
    let(:job_command) { ['bundle', 'exec', 'barbeque:execute'] }
    let(:hako_env) { { 'AWS_REGION' => 'ap-northeast-1' } }
    let(:envs) { { 'FOO' => 'BAR' } }
    let(:app) { FactoryGirl.create(:app, docker_image: "#{app_name}:#{tag}") }
    let(:job_definition) { FactoryGirl.create(:job_definition, app: app, command: job_command) }
    let(:job_execution) { FactoryGirl.create(:job_execution, job_definition: job_definition) }

    it 'runs hako oneshot command within HAKO_DIR' do
      expect(Open3).to receive(:capture3).with(
        hako_env,
        'bundle', 'exec', 'hako', 'oneshot', '--tag', tag,
        '--env=FOO=BAR', "/yamls/#{app_name}.yml", '--', *job_command,
        chdir: hako_directory,
      )
      Barbeque::Executor::Hako.new(
        hako_dir: hako_directory,
        hako_env: hako_env,
        yaml_dir: '/yamls',
      ).run(job_execution, envs)
    end
  end
end
