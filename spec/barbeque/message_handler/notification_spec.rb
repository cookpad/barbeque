require 'rails_helper'
require 'barbeque/worker'

describe Barbeque::MessageHandler::Notification do
  describe '#initialize' do
    let(:sns_subscription) { create(:sns_subscription) }
    let(:message) do
      Barbeque::Message::Notification.new(
        Aws::SQS::Types::Message.new(message_id: SecureRandom.uuid, receipt_handle: 'dummy receipt handle', attributes: { 'SentTimestamp' => '1638514604302' }),
        {
          'TopicArn'  => sns_subscription.topic_arn,
          'Message'   => ['hello'].to_json,
        }
      )
    end
    let(:message_queue) { Barbeque::MessageQueue.new(sns_subscription.job_queue) }

    it 'creates Notification message handler from Notification message' do
      handler = Barbeque::MessageHandler::Notification.new(message: message, message_queue: message_queue)
      expect(handler).to be_a(Barbeque::MessageHandler::JobExecution)
    end
  end
end
