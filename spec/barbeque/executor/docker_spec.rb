require 'rails_helper'
require 'barbeque/executor/docker'

RSpec.describe Barbeque::Executor::Docker do
  let(:executor) { described_class.new({}) }
  let(:command) { ['rake', 'test'] }
  let(:job_definition) { FactoryBot.create(:job_definition, command: ['rake', 'test']) }
  let(:job_execution) { FactoryBot.create(:job_execution, job_definition: job_definition, status: :pending) }
  let(:container_id) { '59efea4938e5d11ff6e70441d7442614dc1da014e64a8144c87a7608e27e240c' }
  let(:sqs_client) { instance_double(Aws::SQS::Client) }

  around do |example|
    original = ENV['BARBEQUE_HOST']
    ENV['BARBEQUE_HOST'] = 'https://barbeque'
    example.run
    ENV['BARBEQUE_HOST'] = original
  end

  before do
    allow(Barbeque::MessageRetryingService).to receive(:sqs_client).and_return(sqs_client)
  end

  describe 'job_execution' do
    describe '#start_execution' do
      let(:status) { double('Process::Status', success?: true) }
      let(:stdout) { container_id }
      let(:stderr) { '' }

      it 'starts Docker container' do
        expect(Open3).to receive(:capture3).with('docker', 'run', '--detach', job_execution.job_definition.app.docker_image, 'rake', 'test').and_return([stdout, stderr, status])
        executor.start_execution(job_execution, {})
        expect(Barbeque::DockerContainer.where(message_id: job_execution.message_id, container_id: container_id)).to be_exist
      end

      it 'sets running status' do
        expect(Open3).to receive(:capture3).with('docker', 'run', '--detach', job_execution.job_definition.app.docker_image, 'rake', 'test').and_return([stdout, stderr, status])
        expect(job_execution).to be_pending
        executor.start_execution(job_execution, {})
        job_execution.reload
        expect(job_execution).to be_running
      end

      context 'when docker-run fails' do
        before do
          expect(status).to receive(:success?).and_return(false)
        end

        it 'sets failed status' do
          expect(Open3).to receive(:capture3).with('docker', 'run', '--detach', job_execution.job_definition.app.docker_image, 'rake', 'test').and_return([stdout, stderr, status])
          expect(Barbeque::ExecutionLog).to receive(:try_save_stdout_and_stderr).with(job_execution, stdout, stderr)
          executor.start_execution(job_execution, {})
          job_execution.reload
          expect(job_execution).to be_failed
        end

        context 'with retry_config' do
          before do
            FactoryBot.create(:retry_config, job_definition: job_definition)
          end

          it 'performs retry' do
            expect(Open3).to receive(:capture3).with('docker', 'run', '--detach', job_execution.job_definition.app.docker_image, 'rake', 'test').and_return([stdout, stderr, status])
            expect(Barbeque::ExecutionLog).to receive(:try_save_stdout_and_stderr).with(job_execution, stdout, stderr)
            expect(Barbeque::MessageRetryingService.sqs_client).to receive(:send_message).with(queue_url: a_kind_of(String), message_body: a_kind_of(String), delay_seconds: a_kind_of(Integer))
            executor.start_execution(job_execution, {})
            job_execution.reload
            expect(job_execution).to be_retried
          end
        end
      end
    end

    describe '#poll_execution' do
      let(:inspect_status) { double('Process::Status', success?: true) }
      let(:container_info) do
        {
          'State' => {
            'Status' => 'exited',
            'FinishedAt' => '2017-07-11T09:17:32.013951633Z',
            'ExitCode' => 0,
          },
        }
      end
      let(:stdout) { 'stdout' }
      let(:stderr) { 'stderr' }
      let(:log_status) { double('Process::Status', success?: true) }

      before do
        job_execution.update!(status: :running)
        Barbeque::DockerContainer.create!(message_id: job_execution.message_id, container_id: container_id)
        expect(Open3).to receive(:capture3).with('docker', 'inspect', container_id) {
          [JSON.dump([container_info]), '', inspect_status]
        }
      end

      context 'when job succeeds' do
        it 'sets success status' do
          expect(Open3).to receive(:capture3).with('docker', 'logs', container_id).and_return([stdout, stderr, log_status])
          expect(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr).with(job_execution, stdout, stderr)
          expect(job_execution).to be_running
          executor.poll_execution(job_execution)
          job_execution.reload
          expect(job_execution).to be_success
        end

        context 'when successful slack_notification is configured' do
          let(:slack_client) { double('Barbeque::SlackClient') }
          let(:slack_notification) { FactoryBot.create(:slack_notification, notify_success: true) }

          before do
            job_execution.job_definition.update!(slack_notification: slack_notification)
            allow(Barbeque::SlackClient).to receive(:new).with(slack_notification.channel).and_return(slack_client)
          end

          it 'sends slack notification' do
            expect(Open3).to receive(:capture3).with('docker', 'logs', container_id).and_return([stdout, stderr, log_status])
            expect(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr).with(job_execution, stdout, stderr)
            expect(slack_client).to receive(:notify_success)
            executor.poll_execution(job_execution)
          end
        end
      end

      context 'when job is running' do
        before do
          container_info['State']['Status'] = 'running'
          container_info['State']['FinishedAt'] = '0001-01-01T00:00:00Z'
        end

        it 'does nothing' do
          expect(job_execution).to be_running
          executor.poll_execution(job_execution)
          job_execution.reload
          expect(job_execution).to be_running
        end
      end

      context 'when job fails' do
        before do
          container_info['State']['ExitCode'] = 1
        end

        it 'sets failed status' do
          expect(Open3).to receive(:capture3).with('docker', 'logs', container_id).and_return([stdout, stderr, log_status])
          expect(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr).with(job_execution, stdout, stderr)
          expect(job_execution).to be_running
          executor.poll_execution(job_execution)
          job_execution.reload
          expect(job_execution).to be_failed
        end

        context 'when slack_notification is configured' do
          let(:slack_client) { double('Barbeque::SlackClient') }
          let(:slack_notification) { FactoryBot.create(:slack_notification, notify_success: false) }

          before do
            job_execution.job_definition.update!(slack_notification: slack_notification)
            allow(Barbeque::SlackClient).to receive(:new).with(slack_notification.channel).and_return(slack_client)
          end

          it 'sends slack notification' do
            expect(Open3).to receive(:capture3).with('docker', 'logs', container_id).and_return([stdout, stderr, log_status])
            expect(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr).with(job_execution, stdout, stderr)
            expect(slack_client).to receive(:notify_failure)
            executor.poll_execution(job_execution)
          end
        end

        context 'with retry_config' do
          before do
            FactoryBot.create(:retry_config, job_definition: job_definition)
          end

          it 'performs retry' do
            expect(Open3).to receive(:capture3).with('docker', 'logs', container_id).and_return([stdout, stderr, log_status])
            expect(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr).with(job_execution, stdout, stderr)
            expect(Barbeque::MessageRetryingService.sqs_client).to receive(:send_message).with(queue_url: a_kind_of(String), message_body: a_kind_of(String), delay_seconds: a_kind_of(Integer))
            expect(job_execution).to be_running
            executor.poll_execution(job_execution)
            job_execution.reload
            expect(job_execution).to be_retried
          end
        end

        context 'with retry_config and slack_notification (notify_failure_only_if_retry_limit_reached: false)' do
          let(:slack_client) { double('Barbeque::SlackClient') }
          let(:slack_notification) { FactoryBot.create(:slack_notification, notify_success: false) }

          before do
            job_execution.job_definition.update!(slack_notification: slack_notification)
            allow(Barbeque::SlackClient).to receive(:new).with(slack_notification.channel).and_return(slack_client)
            FactoryBot.create(:retry_config, job_definition: job_definition)
          end

          it 'sends slack notification' do
            expect(Open3).to receive(:capture3).with('docker', 'logs', container_id).and_return([stdout, stderr, log_status])
            expect(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr).with(job_execution, stdout, stderr)
            expect(Barbeque::MessageRetryingService.sqs_client).to receive(:send_message).with(queue_url: a_kind_of(String), message_body: a_kind_of(String), delay_seconds: a_kind_of(Integer))
            expect(slack_client).to receive(:notify_failure)
            executor.poll_execution(job_execution)
          end
        end

        context 'with retry_config and slack_notification (notify_failure_only_if_retry_limit_reached: true)' do
          let(:slack_client) { double('Barbeque::SlackClient') }
          let(:slack_notification) { FactoryBot.create(:slack_notification, notify_success: false, notify_failure_only_if_retry_limit_reached: true) }

          before do
            job_execution.job_definition.update!(slack_notification: slack_notification)
            allow(Barbeque::SlackClient).to receive(:new).with(slack_notification.channel).and_return(slack_client)
            FactoryBot.create(:retry_config, job_definition: job_definition)
          end

          it 'does not send slack notification' do
            expect(Open3).to receive(:capture3).with('docker', 'logs', container_id).and_return([stdout, stderr, log_status])
            expect(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr).with(job_execution, stdout, stderr)
            expect(Barbeque::MessageRetryingService.sqs_client).to receive(:send_message).with(queue_url: a_kind_of(String), message_body: a_kind_of(String), delay_seconds: a_kind_of(Integer))
            expect(slack_client).not_to receive(:notify_failure)
            executor.poll_execution(job_execution)
          end
        end
      end
    end
  end

  describe 'job_retry' do
    let(:job_retry) { FactoryBot.create(:job_retry, job_execution: job_execution, status: :pending) }
    let(:status) { double('Process::Status', success?: true) }
    let(:stdout) { container_id }
    let(:stderr) { '' }

    before do
      job_execution.update!(status: :failed)
    end

    describe '#start_retry' do
      it 'starts Docker container' do
        expect(Open3).to receive(:capture3).with('docker', 'run', '--detach', job_execution.job_definition.app.docker_image, 'rake', 'test').and_return([stdout, stderr, status])
        executor.start_retry(job_retry, {})
        expect(Barbeque::DockerContainer.where(message_id: job_retry.message_id, container_id: container_id)).to be_exist
      end

      it 'sets running status' do
        expect(Open3).to receive(:capture3).with('docker', 'run', '--detach', job_execution.job_definition.app.docker_image, 'rake', 'test').and_return([stdout, stderr, status])
        expect(job_retry).to be_pending
        expect(job_execution).to be_failed
        executor.start_retry(job_retry, {})
        job_retry.reload
        job_execution.reload
        expect(job_retry).to be_running
        expect(job_execution).to be_retried
      end

      context 'when docker-run fails' do
        before do
          expect(status).to receive(:success?).and_return(false)
        end

        it 'sets failed status' do
          expect(Open3).to receive(:capture3).with('docker', 'run', '--detach', job_execution.job_definition.app.docker_image, 'rake', 'test').and_return([stdout, stderr, status])
          expect(Barbeque::ExecutionLog).to receive(:try_save_stdout_and_stderr).with(job_retry, stdout, stderr)
          expect(job_retry).to be_pending
          expect(job_execution).to be_failed
          executor.start_retry(job_retry, {})
          job_retry.reload
          job_execution.reload
          expect(job_retry).to be_failed
          expect(job_execution).to be_failed
        end

        context 'with retry_config' do
          before do
            FactoryBot.create(:retry_config, job_definition: job_definition)
          end

          it 'performs retry' do
            expect(Open3).to receive(:capture3).with('docker', 'run', '--detach', job_execution.job_definition.app.docker_image, 'rake', 'test').and_return([stdout, stderr, status])
            expect(Barbeque::ExecutionLog).to receive(:try_save_stdout_and_stderr).with(job_retry, stdout, stderr)
            expect(Barbeque::MessageRetryingService.sqs_client).to receive(:send_message).with(queue_url: a_kind_of(String), message_body: a_kind_of(String), delay_seconds: a_kind_of(Integer))
            expect(job_retry).to be_pending
            expect(job_execution).to be_failed
            executor.start_retry(job_retry, {})
            job_retry.reload
            job_execution.reload
            expect(job_retry).to be_failed
            expect(job_execution).to be_retried
          end
        end
      end
    end

    describe '#poll_retry' do
      let(:inspect_status) { double('Process::Status', success?: true) }
      let(:container_info) do
        {
            'State' => {
              'Status' => 'exited',
              'FinishedAt' => '2017-07-11T09:17:32.013951633Z',
              'ExitCode' => 0,
            },
        }
      end
      let(:stdout) { 'stdout' }
      let(:stderr) { 'stderr' }
      let(:log_status) { double('Process::Status', success?: true) }

      before do
        job_execution.update!(status: :retried)
        job_retry.update!(status: :running)
        Barbeque::DockerContainer.create!(message_id: job_retry.message_id, container_id: container_id)
        expect(Open3).to receive(:capture3).with('docker', 'inspect', container_id) {
          [JSON.dump([container_info]), '', inspect_status]
        }
      end

      context 'when retried job succeeds' do
        it 'sets success status' do
          expect(Open3).to receive(:capture3).with('docker', 'logs', container_id).and_return([stdout, stderr, log_status])
          expect(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr).with(job_retry, stdout, stderr)
          expect(job_retry).to be_running
          expect(job_execution).to be_retried
          executor.poll_retry(job_retry)
          job_retry.reload
          job_execution.reload
          expect(job_retry).to be_success
          expect(job_execution).to be_success
        end

        context 'when successful slack_notification is configured' do
          let(:slack_client) { double('Barbeque::SlackClient') }
          let(:slack_notification) { FactoryBot.create(:slack_notification, notify_success: true) }

          before do
            allow(Barbeque::SlackClient).to receive(:new).with(slack_notification.channel).and_return(slack_client)
          end

          it 'sends slack notification' do
            expect(Open3).to receive(:capture3).with('docker', 'logs', container_id).and_return([stdout, stderr, log_status])
            expect(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr).with(job_retry, stdout, stderr)
            job_execution.job_definition.update!(slack_notification: slack_notification)
            expect(slack_client).to receive(:notify_success)
            executor.poll_retry(job_retry)
          end
        end
      end

      context 'when retried job is running' do
        before do
          container_info['State']['Status'] = 'running'
          container_info['State']['FinishedAt'] = '0001-01-01T00:00:00Z'
        end

        it 'does nothing' do
          expect(job_retry).to be_running
          expect(job_execution).to be_retried
          executor.poll_retry(job_retry)
          job_retry.reload
          job_execution.reload
          expect(job_retry).to be_running
          expect(job_execution).to be_retried
        end
      end

      context 'when retried job fails' do
        before do
          container_info['State']['ExitCode'] = 1
        end

        it 'sets failed status' do
          expect(Open3).to receive(:capture3).with('docker', 'logs', container_id).and_return([stdout, stderr, log_status])
          expect(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr).with(job_retry, stdout, stderr)
          expect(job_retry).to be_running
          expect(job_execution).to be_retried
          executor.poll_retry(job_retry)
          job_retry.reload
          job_execution.reload
          expect(job_retry).to be_failed
          expect(job_execution).to be_failed
        end

        context 'when slack_notification is configured' do
          let(:slack_client) { double('Barbeque::SlackClient') }
          let(:slack_notification) { FactoryBot.create(:slack_notification, notify_success: false) }

          before do
            job_execution.job_definition.update!(slack_notification: slack_notification)
            allow(Barbeque::SlackClient).to receive(:new).with(slack_notification.channel).and_return(slack_client)
          end

          it 'sends slack notification' do
            expect(Open3).to receive(:capture3).with('docker', 'logs', container_id).and_return([stdout, stderr, log_status])
            expect(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr).with(job_retry, stdout, stderr)
            expect(slack_client).to receive(:notify_failure)
            executor.poll_retry(job_retry)
          end
        end

        context 'with retry_config' do
          before do
            FactoryBot.create(:retry_config, job_definition: job_definition)
          end

          it 'performs retry' do
            expect(Open3).to receive(:capture3).with('docker', 'logs', container_id).and_return([stdout, stderr, log_status])
            expect(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr).with(job_retry, stdout, stderr)
            expect(Barbeque::MessageRetryingService.sqs_client).to receive(:send_message).with(queue_url: a_kind_of(String), message_body: a_kind_of(String), delay_seconds: a_kind_of(Integer))
            expect(job_retry).to be_running
            expect(job_execution).to be_retried
            executor.poll_retry(job_retry)
            job_retry.reload
            job_execution.reload
            expect(job_retry).to be_failed
            expect(job_execution).to be_retried
          end
        end

        context 'when retried job fails for retry limit of times' do
          let(:slack_client) { double('Barbeque::SlackClient') }
          let(:container_id2) { '40fa4fcb316f90f65d70717f66357e065747f8c216f392817bb8237f51dc416e' }
          let(:job_retry2) { FactoryBot.create(:job_retry, job_execution: job_execution, status: :pending) }

          before do
            job_execution.job_definition.update!(slack_notification: slack_notification)
            allow(Barbeque::SlackClient).to receive(:new).with(slack_notification.channel).and_return(slack_client)
            FactoryBot.create(:retry_config, job_definition: job_definition, retry_limit: 2)
          end

          context 'with retry_config and slack_notification (notify_failure_only_if_retry_limit_reached: false)' do
            let(:slack_notification) { FactoryBot.create(:slack_notification, notify_success: false ) }

            it 'performs retry with sending slack notification for two times' do
              expect(Open3).to receive(:capture3).with('docker', 'logs', container_id).and_return([stdout, stderr, log_status])
              expect(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr).with(job_retry, stdout, stderr)
              expect(Barbeque::MessageRetryingService.sqs_client).to receive(:send_message).with(queue_url: a_kind_of(String), message_body: a_kind_of(String), delay_seconds: a_kind_of(Integer))
              expect(slack_client).to receive(:notify_failure).twice
              executor.poll_retry(job_retry)

              Barbeque::DockerContainer.create!(message_id: job_retry2.message_id, container_id: container_id2)
              expect(Open3).to receive(:capture3).with('docker', 'logs', container_id2).and_return([stdout, stderr, log_status])
              expect(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr).with(job_retry2, stdout, stderr)
              expect(Open3).to receive(:capture3).with('docker', 'inspect', container_id2) {
                [JSON.dump([container_info]), '', inspect_status]
              }
              executor.poll_retry(job_retry2)
            end
          end

          context 'with retry_config and slack_notification (notify_failure_only_if_retry_limit_reached: true)' do
            let(:slack_notification) { FactoryBot.create(:slack_notification, notify_success: false, notify_failure_only_if_retry_limit_reached: true) }

            it 'performs retry with sending only one slack notification' do
              expect(Open3).to receive(:capture3).with('docker', 'logs', container_id).and_return([stdout, stderr, log_status])
              expect(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr).with(job_retry, stdout, stderr)
              expect(Barbeque::MessageRetryingService.sqs_client).to receive(:send_message).with(queue_url: a_kind_of(String), message_body: a_kind_of(String), delay_seconds: a_kind_of(Integer))
              expect(slack_client).to receive(:notify_failure).once
              executor.poll_retry(job_retry)

              Barbeque::DockerContainer.create!(message_id: job_retry2.message_id, container_id: container_id2)
              expect(Open3).to receive(:capture3).with('docker', 'logs', container_id2).and_return([stdout, stderr, log_status])
              expect(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr).with(job_retry2, stdout, stderr)
              expect(Open3).to receive(:capture3).with('docker', 'inspect', container_id2) {
                [JSON.dump([container_info]), '', inspect_status]
              }
              executor.poll_retry(job_retry2)
            end
          end
        end
      end
    end
  end
end
