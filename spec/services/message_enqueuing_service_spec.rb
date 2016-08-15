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
    let(:kuroko2_definition_id) { '123' }

    before do
      allow(Aws::SQS::Client).to receive(:new).and_return(sqs_client)
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
      ).and_return(send_message_result)

      result = Barbeque::MessageEnqueuingService.new(
        job:     job,
        queue:   job_queue.name,
        message: message,
        application: application,
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
          ).run
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
