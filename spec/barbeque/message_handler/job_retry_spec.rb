require 'rails_helper'
require 'barbeque/worker'

describe Barbeque::MessageHandler::JobRetry do
  describe '#run' do
    let(:handler) { Barbeque::MessageHandler::JobRetry.new(message: message, job_queue: job_queue) }
    let(:job_queue) { create(:job_queue) }
    let(:job_definition) { create(:job_definition) }
    let(:job_execution) { create(:job_execution, status: :failed, job_definition: job_definition, job_queue: job_queue) }
    let(:message) do
      Barbeque::Message::JobRetry.new(
        Aws::SQS::Types::Message.new(message_id: SecureRandom.uuid, receipt_handle: 'dummy receipt handle'),
        { "RetryMessageId" => job_execution.message_id },
      )
    end
    let(:message_body)  { '["dummy"]' }
    let(:status) { double('Process::Status', success?: true) }
    let(:executor) { double('Barbeque::Executor::Docker', run: ['stdout', 'stderr', status]) }

    before do
      allow(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr)
      allow(Barbeque::ExecutionLog).to receive(:load).with(execution: job_execution).and_return({ 'message' => message_body })

      docker_image = Barbeque::DockerImage.new(job_definition.app.docker_image)
      allow(Barbeque::DockerImage).to receive(:new).with(job_definition.app.docker_image).and_return(docker_image)
      allow(Barbeque::Executor::Docker).to receive(:new).with(docker_image: docker_image).and_return(executor)
    end

    around do |example|
      ENV['BARBEQUE_HOST'] = 'https://barbeque'
      example.run
      ENV.delete('BARBEQUE_HOST')
    end

    it 'runs a command with executor' do
      expect(executor).to receive(:run).with(
        job_definition.command,
        {
          'BARBEQUE_JOB'         => job_definition.job,
          'BARBEQUE_MESSAGE'     => message_body,
          'BARBEQUE_MESSAGE_ID'  => job_execution.message_id,
          'BARBEQUE_QUEUE_NAME'  => job_queue.name,
          'BARBEQUE_RETRY_COUNT' => '1',
        },
      )
      handler.run
    end

    it 'sets running status during run_command' do
      expect(Barbeque::JobRetry.count).to eq(0)
      expect(executor).to receive(:run) { |command, envs|
        expect(command).to eq(job_definition.command)
        expect(Barbeque::JobRetry.count).to eq(1)
        expect(Barbeque::JobRetry.last).to be_running
        ['stdout', 'stderr', status]
      }
      handler.run
      expect(Barbeque::JobRetry.count).to eq(1)
      expect(Barbeque::JobRetry.last).to_not be_running
    end
    it 'logs stdout and stderr to S3' do
      expect(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr).with(a_kind_of(Barbeque::JobRetry), 'stdout', 'stderr')
      handler.run
    end

    it 'creates job_retry associated to job_execution in the message' do
      expect { handler.run }.to change(Barbeque::JobRetry, :count).by(1)
      job_retry = Barbeque::JobRetry.last
      expect(job_retry.finished_at).to be_a(Time)
      expect(job_retry.job_execution).to eq(job_execution)
      expect(job_retry.status).to eq('success')
    end

    context 'with retry succeeded' do
      it 'changes status of job_execution to success' do
        expect {
          handler.run
        }.to change {
          job_execution.reload.status
        }.from('failed').to('success')
      end

      context 'when successuful slack_notification is configured' do
        let(:slack_client) { double('Barbeque::SlackClient') }
        let(:job_definition) { create(:job_definition, slack_notification: slack_notification) }
        let(:slack_notification) { create(:slack_notification, notify_success: true) }

        before do
          allow(Barbeque::SlackClient).to receive(:new).with(slack_notification.channel).and_return(slack_client)
        end

        it 'sends slack notification' do
          expect(slack_client).to receive(:notify_success)
          handler.run
        end
      end
    end

    context 'with retry failed' do
      let(:status) { double('Process::Status', success?: false) }

      it 'does not change status of job_execution' do
        expect {
          handler.run
        }.to_not change {
          job_execution.reload.status
        }.from('failed')
      end

      context 'when slack_notification is configured' do
        let(:slack_client) { double('Barbeque::SlackClient') }
        let(:job_definition) { create(:job_definition, slack_notification: slack_notification) }
        let(:slack_notification) { create(:slack_notification, notify_success: false) }

        before do
          allow(Barbeque::SlackClient).to receive(:new).with(slack_notification.channel).and_return(slack_client)
        end

        it 'sends slack notification' do
          expect(slack_client).to receive(:notify_failure)
          handler.run
        end
      end
    end

    context 'when retried message is missing' do
      before do
        allow(Barbeque::ExecutionLog).to receive(:load).with(execution: job_execution).and_return(nil)
      end

      it 'raises MessageNotFound' do
        expect { handler.run }.to raise_error(Barbeque::MessageHandler::MessageNotFound)
      end
    end

    context 'when job_retry already exists' do
      before do
        create(:job_retry, message_id: message.id)
      end

      it 'raises DuplicatedExecution' do
        expect { handler.run }.to raise_error(Barbeque::MessageHandler::DuplicatedExecution)
      end
    end

    context 'when unhandled exception is raised' do
      let(:exception) { Class.new(StandardError) }

      before do
        expect(executor).to receive(:run).and_raise(exception)
      end

      it 'updates status to error' do
        expect(job_execution).to be_failed
        expect(Barbeque::JobRetry.count).to eq(0)
        expect { handler.run }.to raise_error(exception)
        expect(Barbeque::JobRetry.last).to be_error
        expect(job_execution.reload).to be_error
      end

      it 'logs empty output' do
        expect(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr).with(a_kind_of(Barbeque::JobRetry), '', '')
        expect { handler.run }.to raise_error(exception)
      end
    end
  end
end
