require 'rails_helper'

describe Barbeque::SnsSubscriptionsController do
  routes { Barbeque::Engine.routes }

  before do
    allow(Barbeque::SNSSubscriptionService).to receive(:sqs_client).and_return(sqs_client)
    allow(Barbeque::SNSSubscriptionService).to receive(:sns_client).and_return(sns_client)
  end

  describe '#create' do
    let(:job_queue) { create(:job_queue) }
    let(:job_definition) { create(:job_definition) } 
    let(:sqs_client) do
      double(
        'Aws::SQS::Client',
        get_queue_attributes: get_queue_attrs_response,
        set_queue_attributes: set_queue_attrs_response,
      ) 
    end
    let(:get_queue_attrs_response) do
      double(
        'Aws::SQS::Types::GetQueueAttributesResult',
        attributes: { 'QueueArn' => "arn:aws:sqs:ap-northeast-1:123456789012:#{job_queue.name}" }
      )
    end
    let(:set_queue_attrs_response) { double('Aws::SQS::Types::SetQueueAttributesResult') }

    let(:topic_arn) { 'arn:aws:sns:ap-northeast-1:123456789012:Topic-X' }
    let(:queue_arn) { "arn:aws:sqs:ap-northeast-1:123456789012:#{job_queue.name}" }
    let(:attributes) do
      {
        topic_arn: topic_arn,
        job_queue_id: job_queue.id,
        job_definition_id: job_definition.id,
      }
    end

    let(:sns_client) do
      double(
        'Aws::SNS::Client',
        subscribe: subscribe_response,
      ) 
    end
    let(:subscribe_response) { double('Aws::SNS::Types::SubscribeResult') }

    it 'creates a record and sends request to SQS validly' do
      expect(sqs_client).to receive(:get_queue_attributes).with(queue_url: job_queue.queue_url, attribute_names: ['QueueArn'])
      expect(sqs_client).to receive(:set_queue_attributes).
        with(
          queue_url: job_queue.queue_url,
          attributes: {
            'Policy' => "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"sqs:SendMessage\",\"Resource\":\"#{queue_arn}\",\"Condition\":{\"ArnEquals\":{\"aws:SourceArn\":[\"#{topic_arn}\"]}}}]}"
          }
        )
      expect(sns_client).to receive(:subscribe).with(topic_arn: topic_arn, protocol: 'sqs', endpoint: queue_arn)
      expect { post :create , params: { sns_subscription: attributes } }.
        to change { Barbeque::SNSSubscription.count }.by(1)
    end

    context 'with NotFound error' do
      it 'does not create a record and shows error message' do
        expect(sqs_client).to receive(:get_queue_attributes).with(queue_url: job_queue.queue_url, attribute_names: ['QueueArn'])
        expect(sns_client).to receive(:subscribe).and_raise(Aws::SNS::Errors::NotFound.new(self, 'not found'))
        allow(controller).to receive(:fetch_sns_topic_arns).and_return([])
        post :create , params: { sns_subscription: attributes }
        expect(response).to render_template(:new)
        expect(assigns(:sns_subscription).errors[:topic_arn]).to eq(['is not found'])
      end
    end

    context 'with AuthorizationError' do
      it 'does not create a record and shows error message' do
        expect(sqs_client).to receive(:get_queue_attributes).with(queue_url: job_queue.queue_url, attribute_names: ['QueueArn'])
        expect(sns_client).to receive(:subscribe).and_raise(Aws::SNS::Errors::AuthorizationError.new(self, 'not found'))
        allow(controller).to receive(:fetch_sns_topic_arns).and_return([])
        post :create , params: { sns_subscription: attributes }
        expect(response).to render_template(:new)
        expect(assigns(:sns_subscription).errors[:topic_arn]).to eq(['is not authorized'])
      end
    end
  end

  describe '#destroy' do
    let(:sns_subscription) { create(:sns_subscription) }
    let(:subscription_arn) { "#{sns_subscription.topic_arn}:71bcbe40-929e-4613-87b1-900a6a0abbfd" }
    let(:sqs_client) do
      double(
        'Aws::SQS::Client',
        get_queue_attributes: get_queue_attrs_response,
        set_queue_attributes: set_queue_attrs_response,
      ) 
    end
    let(:queue_arn) { "arn:aws:sqs:ap-northeast-1:123456789012:#{sns_subscription.job_queue.name}" }
    let(:get_queue_attrs_response) { double('Aws::SQS::Types::GetQueueAttributesResult', attributes: { 'QueueArn' => queue_arn }) }
    let(:set_queue_attrs_response) { double('Aws::SQS::Types::SetQueueAttributesResult') }

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

    it 'destroys the record and sends request to SQS validly' do
      expect(sqs_client).to receive(:get_queue_attributes).with(queue_url: sns_subscription.job_queue.queue_url, attribute_names: ['QueueArn'])
      expect(sns_client).to receive(:list_subscriptions_by_topic).with(topic_arn: sns_subscription.topic_arn)
      expect(sns_client).to receive(:unsubscribe).with(subscription_arn: subscription_arn)
      expect(sqs_client).to receive(:set_queue_attributes).
        with(
          queue_url: sns_subscription.job_queue.queue_url,
          attributes: {
            'Policy' => ''
          }
        )
      expect { delete :destroy, params: { id: sns_subscription.id } }.
        to change { Barbeque::SNSSubscription.count }.by(-1)
    end
  end
end
