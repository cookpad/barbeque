require 'rails_helper'
require 'barbeque/worker'

describe Barbeque::MessageQueue do
  describe '#dequeue' do
    let(:job_queue) { create(:job_queue) }
    let(:message_queue) { Barbeque::MessageQueue.new(job_queue) }
    let(:client) { double('Aws::SQS::Client') }
    let(:result) { Aws::SQS::Types::ReceiveMessageResult.new(messages: [raw_message]) }
    let(:message_id) { SecureRandom.uuid }
    let(:receipt_handle) { 'receipt handle' }
    let(:job) { 'NotifyAuthor' }
    let(:type) { 'JobExecution' }
    let(:raw_message) do
      Aws::SQS::Types::Message.new(
        message_id: message_id,
        receipt_handle: receipt_handle,
        body: { 'Type' => type, 'Job' => job }.to_json,
        attributes: { 'SentTimestamp' => '1638514604302' },
      )
    end
    let(:message) { Barbeque::Message.parse(raw_message) }

    before do
      allow(Aws::SQS::Client).to receive(:new).and_return(client)
      allow(client).to receive(:receive_message).and_return(result)
      allow(client).to receive(:delete_message, &:itself)
    end

    it 'returns a message received from SQS' do
      message = message_queue.dequeue
      expect(message.type).to eq(type)
      expect(message.id).to eq(message_id)
      expect(message.receipt_handle).to eq(receipt_handle)
      expect(message.job).to eq(job)
    end
  end
end
