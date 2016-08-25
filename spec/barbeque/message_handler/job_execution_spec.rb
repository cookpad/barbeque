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
    let(:runner) { double('Barbeque::Runner::Docker', run: ['stdout', 'stderr', status]) }

    before do
      docker_image = Barbeque::DockerImage.new(job_definition.app.docker_image)
      allow(Barbeque::DockerImage).to receive(:new).with(job_definition.app.docker_image).and_return(docker_image)
      allow(Barbeque::Runner::Docker).to receive(:new).with(docker_image: docker_image).and_return(runner)
      allow(Barbeque::ExecutionLog).to receive(:save)
    end

    around do |example|
      ENV['BARBEQUE_HOST'] = 'https://barbeque'
      example.run
      ENV.delete('BARBEQUE_HOST')
    end

    it 'creates job_execution associated to job_definition in the message and job_queue' do
      expect { handler.run }.to change(JobExecution, :count).by(1)
      expect(JobExecution.last.finished_at).to be_a(Time)
      expect(JobExecution.last.job_definition).to eq(job_definition)
      expect(JobExecution.last.job_queue).to eq(job_queue)
    end

    it 'logs message, stdout and stderr to S3' do
      expect(Barbeque::ExecutionLog).to receive(:save).with(
        execution: a_kind_of(JobExecution),
        log: { message: message.body.to_json, stdout: 'stdout', stderr: 'stderr' },
      )
      handler.run
    end

    it 'runs command with runner' do
      expect(runner).to receive(:run).with(
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

    context 'when job succeeded' do
      it 'sets job_executions.status :success' do
        handler.run
        expect(JobExecution.last.status).to eq('success')
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
        expect(JobExecution.last.status).to eq('failed')
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
  end
end
