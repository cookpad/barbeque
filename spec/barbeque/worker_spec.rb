require 'rails_helper'
require 'barbeque/worker'

describe Barbeque::Worker do
  let!(:job_execution) { create(:job_execution, message_id: message_id, status: 'pending') }
  let(:job_queue) { create(:job_queue) }
  let(:message_queue) { double('Barbeque::MessageQueue', dequeue: message, job_queue: job_queue) }
  let(:message_body) { '{}' }
  let(:message_id) { SecureRandom.uuid }
  let(:is_success) { true }
  let(:stdout) { "hello world\n" }
  let(:stderr) { "\n" }
  let(:status) { double('Process::Status', success?: is_success) }
  let(:job) { double('Barbeque::MessageHandler::JobExecution', run: [stdout, stderr, status]) }
  let(:worker_class) do
    Class.new do
      cattr_accessor :worker_id
      def worker_id
        self.class.worker_id
      end

      include Barbeque::Worker
    end
  end
  let(:worker) { worker_class.new }

  before do
    allow(Barbeque::MessageQueue).to receive(:new).and_return(message_queue)
    allow(Barbeque::MessageHandler::JobExecution).to receive(:new).with(message: message, message_queue: message_queue).and_return(job)
  end

  describe '#execute_command' do
    let(:message) { double('Barbeque::Message::Base', body: message_body, id: message_id, type: 'JobExecution') }

    context 'with worker_id = 0' do
      before do
        worker_class.worker_id = 0
      end

      it 'runs ExecutionPoller' do
        expect_any_instance_of(Barbeque::ExecutionPoller).to receive(:run)
        worker.execute_command
      end
    end

    context 'with worker_id = 1' do
      before do
        worker_class.worker_id = 1
      end

      it 'runs RetryPoller' do
        expect_any_instance_of(Barbeque::RetryPoller).to receive(:run)
        worker.execute_command
      end
    end

    context 'with worker_id >= 2' do
      let(:runner) { Barbeque::Runner.new(queue_name: job_queue.name) }

      before do
        worker_class.worker_id = 2
        allow(Barbeque::Runner).to receive(:new).and_return(runner)
      end

      it 'runs Runner' do
        expect(runner).to receive(:run)
        worker.execute_command
      end

      it 'runs a job' do
        expect(job).to receive(:run).and_return([stdout, stderr, status])
        worker.execute_command
      end

      context 'given JobRetry message' do
        let(:retry_message_id) { SecureRandom.uuid }
        let(:message) do
          double(
            'Barbeque::Message::Base',
            body: message_body,
            id: retry_message_id,
            type: 'JobRetry',
            retry_message_id: job_execution.message_id,
          )
        end
        let(:execution_retry) { Barbeque::MessageHandler::JobRetry.new(message: message, message_queue: message_queue) }

        before do
          create(:job_retry, job_execution: job_execution, message_id: retry_message_id)
          allow(Barbeque::MessageHandler::JobRetry).to receive(:new).
            with(message: message, message_queue: message_queue).and_return(execution_retry)
          allow(execution_retry).to receive(:run).and_return([stdout, stderr, status])
        end

        it 'retries the specified message' do
          expect(execution_retry).to receive(:run)
          worker_class.new.execute_command
        end
      end
    end
  end
end
