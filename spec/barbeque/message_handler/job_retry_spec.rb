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
    let(:runner) { double('Barbeque::Runner::Docker', run: ['stdout', 'stderr', status]) }

    before do
      allow(Barbeque::ExecutionLog).to receive(:save)
      allow(Barbeque::ExecutionLog).to receive(:load).with(execution: job_execution).and_return({ 'message' => message_body })

      docker_image = Barbeque::DockerImage.new(job_definition.app.docker_image)
      allow(Barbeque::DockerImage).to receive(:new).with(job_definition.app.docker_image).and_return(docker_image)
      allow(Barbeque::Runner::Docker).to receive(:new).with(docker_image: docker_image).and_return(runner)
    end

    around do |example|
      ENV['BARBEQUE_HOST'] = 'https://barbeque'
      example.run
      ENV.delete('BARBEQUE_HOST')
    end

    it 'runs a command with runner' do
      expect(runner).to receive(:run).with(
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

    it 'logs stdout and stderr to S3' do
      expect(Barbeque::ExecutionLog).to receive(:save).with(
        execution: a_kind_of(JobRetry),
        log: { stdout: 'stdout', stderr: 'stderr' },
      )
      handler.run
    end

    it 'creates job_retry associated to job_execution in the message' do
      expect { handler.run }.to change(JobRetry, :count).by(1)
      expect(JobRetry.last.finished_at).to be_a(Time)
      expect(JobRetry.last.job_execution).to eq(job_execution)
      expect(JobRetry.last.status).to eq('success')
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
  end
end
