require 'rails_helper'
require 'barbeque/worker'

describe Barbeque::MessageHandler::JobExecution do
  describe '#run' do
    let(:handler) { Barbeque::MessageHandler::JobExecution.new(message: message, job_queue: job_queue) }
    let(:job_definition) { create(:job_definition) }
    let(:job_queue)      { create(:job_queue) }
    let(:message) do
      Barbeque::Message::JobExecution.new(
        Aws::SQS::Types::Message.new(message_id: SecureRandom.uuid, receipt_handle: 'dummy receipt handle'),
        {
          'Application' => job_definition.app.name,
          'Job'         => job_definition.job,
          'Message'     => ['hello'],
        }
      )
    end
    let(:status) { double('Process::Status', success?: true) }
    let(:executor) { double('Barbeque::Executor::Docker', run: ['stdout', 'stderr', status]) }

    before do
      docker_image = Barbeque::DockerImage.new(job_definition.app.docker_image)
      allow(Barbeque::DockerImage).to receive(:new).with(job_definition.app.docker_image).and_return(docker_image)
      allow(Barbeque::Executor::Docker).to receive(:new).with(docker_image: docker_image).and_return(executor)
      allow(Barbeque::ExecutionLog).to receive(:save_message)
      allow(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr)
    end

    around do |example|
      ENV['BARBEQUE_HOST'] = 'https://barbeque'
      example.run
      ENV.delete('BARBEQUE_HOST')
    end

    it 'creates job_execution associated to job_definition in the message and job_queue' do
      expect { handler.run }.to change(Barbeque::JobExecution, :count).by(1)
      expect(Barbeque::JobExecution.last.finished_at).to be_a(Time)
      expect(Barbeque::JobExecution.last.job_definition).to eq(job_definition)
      expect(Barbeque::JobExecution.last.job_queue).to eq(job_queue)
    end

    it 'logs message, stdout and stderr to S3' do
      expect(Barbeque::ExecutionLog).to receive(:save_message).with(a_kind_of(Barbeque::JobExecution), message)
      expect(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr).with(a_kind_of(Barbeque::JobExecution), 'stdout', 'stderr')
      handler.run
    end

    it 'runs command with executor' do
      expect(executor).to receive(:run).with(
        job_definition.command,
        {
          'BARBEQUE_JOB'         => job_definition.job,
          'BARBEQUE_MESSAGE'     => message.body.to_json,
          'BARBEQUE_MESSAGE_ID'  => message.id,
          'BARBEQUE_QUEUE_NAME'  => job_queue.name,
          'BARBEQUE_RETRY_COUNT' => '0',
        },
      )
      handler.run
    end

    it 'sets running status during run_command' do
      expect(Barbeque::JobExecution.count).to eq(0)
      expect(executor).to receive(:run) { |command, envs|
        expect(command).to eq(job_definition.command)
        expect(Barbeque::JobExecution.count).to eq(1)
        expect(Barbeque::JobExecution.last).to be_running
        ['stdout', 'stderr', status]
      }
      handler.run
      expect(Barbeque::JobExecution.count).to eq(1)
      expect(Barbeque::JobExecution.last).to_not be_running
    end

    context 'when job succeeded' do
      it 'sets job_executions.status :success' do
        handler.run
        expect(Barbeque::JobExecution.last.status).to eq('success')
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

    context 'when job failed' do
      let(:status) { double('Process::Status', success?: false) }

      it 'sets job_executions.status :failed' do
        handler.run
        expect(Barbeque::JobExecution.last.status).to eq('failed')
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

    context 'when job_execution already exists' do
      before do
        create(:job_execution, message_id: message.id)
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
        expect(Barbeque::JobExecution.count).to eq(0)
        expect { handler.run }.to raise_error(exception)
        expect(Barbeque::JobExecution.last).to be_error
      end

      it 'logs message body' do
        expect(Barbeque::ExecutionLog).to receive(:save_message).with(a_kind_of(Barbeque::JobExecution), message)
        expect(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr).with(a_kind_of(Barbeque::JobExecution), '', '')
        expect { handler.run }.to raise_error(exception)
      end
    end
  end
end
