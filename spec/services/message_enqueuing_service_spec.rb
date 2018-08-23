require 'rails_helper'

describe Barbeque::MessageEnqueuingService do
  describe '#run' do
    let(:application) { 'cookpad' }
    let(:job) { 'PostToCuenoteJob' }
    let(:message)    { { 'user_id' => 1 } }
    let(:message_id) { SecureRandom.uuid }
    let(:sqs_client) { double('Aws::SQS::Client') }
    let(:job_queue)  { create(:job_queue) }
    let(:send_message_result) { double('Aws::SQS::Types::SendMessageResult', message_id: message_id) }

    before do
      allow(described_class).to receive(:sqs_client).and_return(sqs_client)
    end

    it 'enqueues a message whose type is JobExecution' do
      expect(sqs_client).to receive(:send_message).with(
        queue_url: job_queue.queue_url,
        message_body: {
          'Type'        => 'JobExecution',
          'Application' => application,
          'Job'         => job,
          'Message'     => message,
        }.to_json,
        delay_seconds: nil,
      ).and_return(send_message_result)

      result = Barbeque::MessageEnqueuingService.new(
        job:     job,
        queue:   job_queue.name,
        message: message,
        application: application,
        delay_seconds: nil,
      ).run
      expect(result).to eq(message_id)
    end

    context 'when specified queue does not exist' do
      let(:queue_name) { 'non-existent queue name' }

      it 'does not enqueue a message' do
        expect(sqs_client).to_not receive(:send_message)
        expect {
          Barbeque::MessageEnqueuingService.new(
            job:     job,
            queue:   queue_name,
            message: message,
            application: application,
            delay_seconds: nil,
          ).run
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when database is unavailable' do
      around do |example|
        env = ENV.to_h
        ENV['BARBEQUE_DATABASE_MAINTENANCE'] = '1'
        ENV['AWS_REGION'] = 'ap-northeast-1'
        ENV['AWS_ACCOUNT_ID'] = '123456789012'
        example.run
        ENV.replace(env)
      end

      it 'builds queue_url without database' do
        expect(sqs_client).to receive(:send_message).with(hash_including(queue_url: job_queue.queue_url)).and_return(send_message_result)
        expect(Barbeque::JobQueue).to_not receive(:connection)

        result = Barbeque::MessageEnqueuingService.new(
          job: job,
          queue: job_queue.name,
          message: message,
          application: application,
          delay_seconds: nil,
        ).run
        expect(result).to eq(message_id)
      end
    end

    context 'with delay_seconds' do
      let(:delay_seconds) { 300 }

      it 'enqueues a message with delay_seconds' do
        expect(sqs_client).to receive(:send_message).with(
          queue_url: job_queue.queue_url,
          message_body: {
            'Type'        => 'JobExecution',
            'Application' => application,
            'Job'         => job,
            'Message'     => message,
          }.to_json,
          delay_seconds: delay_seconds,
        ).and_return(send_message_result)

        result = Barbeque::MessageEnqueuingService.new(
          job:     job,
          queue:   job_queue.name,
          message: message,
          application: application,
          delay_seconds: delay_seconds,
        ).run
        expect(result).to eq(message_id)
      end

      context 'with too large delay_seconds' do
        let(:delay_seconds) { 6000 }
        let(:invalid_parameter_value_exception) do
          Aws::SQS::Errors::InvalidParameterValue.new(nil, "Value #{delay_seconds} for parameter DelaySeconds is invalid. Reason: DelaySeconds must be >= 0 and <= 900.")
        end

        it 'raises BadRequest' do
          expect(sqs_client).to receive(:send_message).with(
            queue_url: job_queue.queue_url,
            message_body: {
              'Type'        => 'JobExecution',
              'Application' => application,
              'Job'         => job,
              'Message'     => message,
            }.to_json,
            delay_seconds: delay_seconds,
          ).and_raise(invalid_parameter_value_exception)

          service = Barbeque::MessageEnqueuingService.new(
            job:     job,
            queue:   job_queue.name,
            message: message,
            application: application,
            delay_seconds: delay_seconds,
          )
          expect { service.run }.to raise_error(Barbeque::MessageEnqueuingService::BadRequest)
        end
      end
    end
  end
end
