require 'rails_helper'
require 'barbeque/worker'

describe Barbeque::MessageHandler::JobExecution do
  describe '#run' do
    let(:handler) { Barbeque::MessageHandler::JobExecution.new(message: message, message_queue: message_queue) }
    let(:job_definition) { create(:job_definition) }
    let(:job_queue)      { create(:job_queue) }
    let(:message_queue) { Barbeque::MessageQueue.new(job_queue) }
    let(:message) do
      Barbeque::Message::JobExecution.new(
        Aws::SQS::Types::Message.new(message_id: SecureRandom.uuid, receipt_handle: 'dummy receipt handle', attributes: { 'SentTimestamp' => '1638514604302' }),
        {
          'Application' => job_definition.app.name,
          'Job'         => job_definition.job,
          'Message'     => ['hello'],
        }
      )
    end
    let(:status) { double('Process::Status', success?: true) }
    let(:open3_result) { ['stdout', 'stderr', status] }
    let(:executor) { double('Barbeque::Executor::Docker') }

    before do
      allow(Barbeque::Executor::Docker).to receive(:new).and_return(executor)
      allow(Barbeque::ExecutionLog).to receive(:save_message)
      allow(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr)
    end

    around do |example|
      ENV['BARBEQUE_HOST'] = 'https://barbeque'
      example.run
      ENV.delete('BARBEQUE_HOST')
    end

    it 'creates job_execution associated to job_definition in the message and job_queue' do
      allow(executor).to receive(:start_execution).and_return(open3_result)
      expect(message_queue).to receive(:delete_message).with(message)
      expect { handler.run }.to change(Barbeque::JobExecution, :count).by(1)
      expect(Barbeque::JobExecution.last.finished_at).to be_nil
      expect(Barbeque::JobExecution.last.job_definition).to eq(job_definition)
      expect(Barbeque::JobExecution.last.job_queue).to eq(job_queue)
    end

    it 'runs command with executor' do
      expect(executor).to receive(:start_execution) { |job_execution, envs|
        expect(job_execution.job_definition).to eq(job_definition)
        expect(envs).to eq(
          'BARBEQUE_JOB'         => job_definition.job,
          'BARBEQUE_MESSAGE'     => message.body.to_json,
          'BARBEQUE_MESSAGE_ID'  => message.id,
          'BARBEQUE_QUEUE_NAME'  => job_queue.name,
          'BARBEQUE_RETRY_COUNT' => '0',
          'BARBEQUE_SENT_TIMESTAMP' => '1638514604302',
        )
      }
      expect(message_queue).to receive(:delete_message).with(message)
      handler.run
    end

    context 'when job_execution already exists' do
      before do
        create(:job_execution, message_id: message.id)
      end

      it 'raises DuplicatedExecution' do
        expect(message_queue).to receive(:delete_message).with(message)
        expect { handler.run }.to raise_error(Barbeque::MessageHandler::DuplicatedExecution)
      end
    end

    context 'when S3 returns error' do
      before do
        expect(Barbeque::ExecutionLog).to receive(:save_message).and_raise(Aws::S3::Errors::InternalError.new(nil, 'We encountered an internal error. Please try again.'))
      end

      it "doesn't create job_execution record" do
        expect { handler.run }.to raise_error(Aws::S3::Errors::InternalError)
        expect(Barbeque::JobExecution.count).to eq(0)
      end
    end

    context 'when sqs:DeleteMessage returns error' do
      before do
        expect(message_queue).to receive(:delete_message).with(message).and_raise(Aws::SQS::Errors::InternalError.new(nil, 'We encountered an internal error. Please try again.'))
      end

      it "doesn't create job_execution record" do
        expect { handler.run }.to raise_error(Aws::SQS::Errors::InternalError)
        expect(Barbeque::JobExecution.count).to eq(0)
      end
    end

    context 'when unhandled exception is raised' do
      let(:exception) { Class.new(StandardError) }

      before do
        expect(executor).to receive(:start_execution).and_raise(exception.new('something went wrong'))
      end

      it 'updates status to error' do
        expect(message_queue).to receive(:delete_message).with(message)
        expect(Barbeque::JobExecution.count).to eq(0)
        expect { handler.run }.to raise_error(exception)
        expect(Barbeque::JobExecution.last).to be_error
      end

      it 'logs message body' do
        expect(message_queue).to receive(:delete_message).with(message)
        expect(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr).with(a_kind_of(Barbeque::JobExecution), '', /something went wrong/)
        expect { handler.run }.to raise_error(exception)
      end
    end
  end
end
