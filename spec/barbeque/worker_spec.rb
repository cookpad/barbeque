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
    Class.new.tap do |klass|
      klass.include Barbeque::Worker
    end
  end

  before do
    allow(Barbeque::MessageQueue).to receive(:new).and_return(message_queue)
    allow(Barbeque::MessageHandler::JobExecution).to receive(:new).with(message: message, job_queue: job_queue).and_return(job)
  end

  describe '#execute_job' do
    let(:message) { double('Barbeque::Message::Base', body: message_body, id: message_id, type: 'JobExecution') }

    it 'runs a job' do
      expect(job).to receive(:run).and_return([stdout, stderr, status])
      worker_class.new.execute_job
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
      let(:execution_retry) { Barbeque::MessageHandler::JobRetry.new(message: message, job_queue: job_queue) }

      before do
        create(:job_retry, job_execution: job_execution, message_id: retry_message_id)
        allow(Barbeque::MessageHandler::JobRetry).to receive(:new).
          with(message: message, job_queue: job_queue).and_return(execution_retry)
        allow(execution_retry).to receive(:run).and_return([stdout, stderr, status])
      end

      it 'retries the specified message' do
        expect(execution_retry).to receive(:run)
        worker_class.new.execute_job
      end
    end
  end
end
