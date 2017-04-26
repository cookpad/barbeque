require 'rails_helper'

RSpec.describe Barbeque::JobQueue do
  describe '#update_policy!' do
    let(:queue) { create(:job_queue) }
    let!(:subscription_a) { create(:sns_subscription, job_queue: queue) }
    let!(:subscription_b) { create(:sns_subscription, job_queue: queue) }
    let(:name) { 'default' }
    let(:queue_name) { Barbeque::JobQueue::SQS_NAME_PREFIX + name }
    let(:queue_url)  { "https://sqs.ap-northeast-1.amazonaws.com/123456789012/#{queue_name}" }
    let(:sqs_client) do
      double(
        'Aws::SQS::Client',
        get_queue_attributes: get_queue_attrs_response,
        set_queue_attributes: set_queue_attrs_response,
      ) 
    end
    let(:get_queue_attrs_response) { double('Aws::SQS::Types::GetQueueAttributesResult', attributes: { 'QueueArn' => "arn:aws:sqs:ap-northeast-1:123456789012:#{queue.name}" }) }
    let(:set_queue_attrs_response) { double('Aws::SQS::Types::SetQueueAttributesResult') }

    before do
      allow(Aws::SQS::Client).to receive(:new).and_return(sqs_client)
    end

    it 'sends request to SQS validly' do
      expect(sqs_client).to receive(:get_queue_attributes).with(queue_url: queue.queue_url, attribute_names: ['QueueArn'])
      expect(sqs_client).to receive(:set_queue_attributes).
        with(
          queue_url: queue.queue_url,
          attributes: {
            'Policy' => "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"sqs:SendMessage\",\"Resource\":\"arn:aws:sqs:ap-northeast-1:123456789012:#{queue.name}\",\"Condition\":{\"ArnEquals\":{\"aws:SourceArn\":[\"#{subscription_a.topic_arn}\",\"#{subscription_b.topic_arn}\"]}}}]}"
          }
        )
      queue.update_policy!
    end
  end
end
