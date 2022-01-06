require 'rails_helper'
require 'barbeque/worker'

describe Barbeque::MessageHandler::JobRetry do
  describe '#run' do
    let(:handler) { Barbeque::MessageHandler::JobRetry.new(message: message, message_queue: message_queue) }
    let(:job_queue) { create(:job_queue) }
    let(:message_queue) { Barbeque::MessageQueue.new(job_queue) }
    let(:job_definition) { create(:job_definition) }
    let(:job_execution) { create(:job_execution, status: :failed, job_definition: job_definition, job_queue: job_queue) }
    let(:message) do
      Barbeque::Message::JobRetry.new(
        Aws::SQS::Types::Message.new(message_id: SecureRandom.uuid, receipt_handle: 'dummy receipt handle', attributes: { 'SentTimestamp' => '1638514604302' }),
        { "RetryMessageId" => job_execution.message_id },
      )
    end
    let(:message_body)  { '["dummy"]' }
    let(:status) { double('Process::Status', success?: true) }
    let(:executor) { double('Barbeque::Executor::Docker') }
    let(:open3_result) { ['stdout', 'stderr', status] }

    before do
      allow(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr)
      allow(Barbeque::ExecutionLog).to receive(:load).with(execution: job_execution).and_return({ 'message' => message_body })
      allow(Barbeque::Executor::Docker).to receive(:new).and_return(executor)
    end

    around do |example|
      ENV['BARBEQUE_HOST'] = 'https://barbeque'
      example.run
      ENV.delete('BARBEQUE_HOST')
    end

    it 'runs a command with executor' do
      expect(executor).to receive(:start_retry) { |job_retry, envs|
        expect(job_retry.job_execution.job_definition).to eq(job_definition)
        expect(envs).to eq(
          'BARBEQUE_JOB'         => job_definition.job,
          'BARBEQUE_MESSAGE'     => message_body,
          'BARBEQUE_MESSAGE_ID'  => job_execution.message_id,
          'BARBEQUE_QUEUE_NAME'  => job_queue.name,
          'BARBEQUE_RETRY_COUNT' => '1',
          'BARBEQUE_SENT_TIMESTAMP' => '1638514604302',
        )
      }
      expect(message_queue).to receive(:delete_message).with(message)
      handler.run
    end

    it 'creates job_retry associated to job_execution in the message' do
      expect(executor).to receive(:start_retry)
      expect(message_queue).to receive(:delete_message).with(message)
      expect { handler.run }.to change(Barbeque::JobRetry, :count).by(1)
      job_retry = Barbeque::JobRetry.last
      expect(job_retry.finished_at).to be_nil
      expect(job_retry.job_execution).to eq(job_execution)
      expect(job_retry).to be_pending
    end

    context 'when retried message is missing' do
      before do
        allow(Barbeque::ExecutionLog).to receive(:load).with(execution: job_execution).and_return(nil)
      end

      it 'raises MessageNotFound' do
        expect(message_queue).to receive(:delete_message).with(message)
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

    context 'when sqs:DeleteMessage returns error' do
      before do
        expect(message_queue).to receive(:delete_message).with(message).and_raise(Aws::SQS::Errors::InternalError.new(nil, 'We encountered an internal error. Please try again.'))
      end

      it "doesn't create job_retries record" do
        expect { handler.run }.to raise_error(Aws::SQS::Errors::InternalError)
        expect(Barbeque::JobRetry.count).to eq(0)
      end
    end

    context 'when unhandled exception is raised' do
      let(:exception) { Class.new(StandardError) }

      before do
        expect(executor).to receive(:start_retry).and_raise(exception.new('something went wrong'))
      end

      it 'updates status to error' do
        expect(message_queue).to receive(:delete_message).with(message)
        expect(job_execution).to be_failed
        expect(Barbeque::JobRetry.count).to eq(0)
        expect { handler.run }.to raise_error(exception)
        expect(Barbeque::JobRetry.last).to be_error
        expect(job_execution.reload).to be_error
      end

      it 'logs empty output' do
        expect(message_queue).to receive(:delete_message).with(message)
        expect(Barbeque::ExecutionLog).to receive(:save_stdout_and_stderr).with(a_kind_of(Barbeque::JobRetry), '', /something went wrong/)
        expect { handler.run }.to raise_error(exception)
      end
    end
  end
end
