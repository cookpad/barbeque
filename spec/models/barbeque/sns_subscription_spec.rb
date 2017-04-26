require 'rails_helper'

RSpec.describe Barbeque::SNSSubscription do
  describe '#create' do
    let(:topic_arn) { 'arn:aws:sns:ap-northest-1:123456789012/Topic' }
    let(:queue) { create(:job_queue) }
    let(:job) { create(:job_definition) }
    let(:sqs_client) do
      double(
        'Aws::SQS::Client',
        get_queue_attributes: get_queue_attrs_response,
      ) 
    end
    let(:queue_arn) { "arn:aws:sqs:ap-northeast-1:123456789012:#{queue.name}" }
    let(:get_queue_attrs_response) { double('Aws::SQS::Types::GetQueueAttributesResult', attributes: { 'QueueArn' => queue_arn }) }
    let(:sns_client) do
      double(
        'Aws::SNS::Client',
        subscribe: subscribe_response,
      ) 
    end
    let(:subscribe_response) { double('Aws::SNS::Types::SubscribeResult') }

    before do
      allow_any_instance_of(Barbeque::SNSSubscription).to receive(:subscribe_topic!).and_call_original
      allow(Aws::SQS::Client).to receive(:new).and_return(sqs_client)
      allow(Aws::SNS::Client).to receive(:new).and_return(sns_client)
    end

    it 'creates record and subscribe SNS topic' do
      expect(sqs_client).to receive(:get_queue_attributes).with(queue_url: queue.queue_url, attribute_names: ['QueueArn'])
      expect(sns_client).to receive(:subscribe).with(topic_arn: topic_arn, protocol: 'sqs', endpoint: queue_arn)
      Barbeque::SNSSubscription.create(topic_arn: topic_arn, job_queue: queue, job_definition: job)
      expect(Barbeque::SNSSubscription.exists?(topic_arn: topic_arn, job_queue: queue, job_definition: job)).to eq(true)
    end
  end

  describe '#destroy' do
    let(:sns_subscription) do
      create(:sns_subscription)
    end
    let(:subscription_arn) { "#{sns_subscription.topic_arn}:71bcbe40-929e-4613-87b1-900a6a0abbfd" }
    let(:sqs_client) do
      double(
        'Aws::SQS::Client',
        get_queue_attributes: get_queue_attrs_response,
      ) 
    end
    let(:queue_arn) { "arn:aws:sqs:ap-northeast-1:123456789012:#{sns_subscription.job_queue.name}" }
    let(:get_queue_attrs_response) { double('Aws::SQS::Types::GetQueueAttributesResult', attributes: { 'QueueArn' => queue_arn }) }
    let(:sns_client) do
      double(
        'Aws::SNS::Client',
        list_subscriptions_by_topic: list_subscriptions_by_topic_response,
        unsubscribe: unsubscribe_response
      ) 
    end
    let(:list_subscriptions_by_topic_response) do
      double(
        'Aws::SNS::Types::ListSubscriptionsByTopicResult',
        subscriptions: [
          double(
            'Aws::SNS::Types::Subscription',
            subscription_arn: subscription_arn,
            endpoint: queue_arn,
          )
        ]
      )
    end
    let(:unsubscribe_response) { double('Aws::SNS:Types:UnsubscribeResult') }

    before do
      allow_any_instance_of(Barbeque::SNSSubscription).to receive(:unsubscribe_topic!).and_call_original
      allow(Aws::SQS::Client).to receive(:new).and_return(sqs_client)
      allow(Aws::SNS::Client).to receive(:new).and_return(sns_client)
    end

    it 'creates record and subscribe SNS topic' do
      expect(sqs_client).to receive(:get_queue_attributes).with(queue_url: sns_subscription.job_queue.queue_url, attribute_names: ['QueueArn'])
      expect(sns_client).to receive(:list_subscriptions_by_topic).with(topic_arn: sns_subscription.topic_arn)
      sns_subscription.destroy
      expect(sns_subscription).to be_destroyed
    end
  end
end
