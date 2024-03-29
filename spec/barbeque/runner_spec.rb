require 'rails_helper'
require 'barbeque/runner'

RSpec.describe Barbeque::Runner do
  let(:job_queue) { create(:job_queue) }
  let(:runner) { described_class.new(job_queue) }
  let(:message_body) do
    JSON.dump(
      'Type' => 'JobExecution',
      'Application' => 'barbeque-spec',
      'Job' => 'BarbequeSpecJob',
      'Message' => { 'FOO' => 'BAR' },
    )
  end
  let(:sqs_message) { Aws::SQS::Types::Message.new(body: message_body, attributes: { 'SentTimestamp' => '1638514604302' }) }
  let(:message) { Barbeque::Message.parse(sqs_message) }
  let(:message_queue) { double('Barbeque::MessageQueue', job_queue: 'default') }
  let(:handler) { double('Barbeque::MessageHandler') }

  before do
    allow(runner).to receive(:message_queue).and_return(message_queue)
    allow(message_queue).to receive(:dequeue).and_return(message)
  end

  describe '#run' do
    context 'with JobExecution message' do
      it 'runs JobExecution message handler' do
        expect(Barbeque::MessageHandler::JobExecution).to receive(:new).and_return(handler)
        expect(handler).to receive(:run)
        runner.run
      end

      context 'with maximum_concurrent_executions' do
        before do
          allow(Barbeque.config).to receive(:maximum_concurrent_executions).and_return(3)
        end

        it 'runs JobExecution message handler without sleep' do
          expect(runner).to_not receive(:sleep)
          expect(Barbeque::MessageHandler::JobExecution).to receive(:new).and_return(handler)
          expect(handler).to receive(:run)
          runner.run
        end

        context "when there's many working executions" do
          before do
            2.times do
              FactoryBot.create(:job_execution, status: :running, job_queue: job_queue)
            end
            retried_executions = 2.times.map { FactoryBot.create(:job_execution, status: :retried, job_queue: job_queue) }
            # One retried execution is already running
            FactoryBot.create(:job_retry, status: :running, job_execution: retried_executions[0])
          end

          it 'waits' do
            expect(runner).to receive(:sleep) { |interval|
              expect(interval).to eq(10)
              # One execution finishes during sleep
              Barbeque::JobExecution.first.update!(status: :success)
            }
            expect(Barbeque::MessageHandler::JobExecution).to receive(:new).and_return(handler)
            expect(handler).to receive(:run)
            runner.run
          end
        end
      end
    end
  end
end
