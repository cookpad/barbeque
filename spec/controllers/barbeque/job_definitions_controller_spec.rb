require 'rails_helper'

describe Barbeque::JobDefinitionsController do
  routes { Barbeque::Engine.routes }

  describe '#index' do
    let!(:job_definition) { create(:job_definition) }

    it 'shows all job_definitions' do
      get :index
      expect(assigns(:job_definitions)).to eq([job_definition])
    end
  end

  describe '#show' do
    let(:job_definition) { create(:job_definition) }
    let!(:job_execution) { create(:job_execution, job_definition: job_definition) }

    it 'shows a requested job_definition' do
      get :show, params: { id: job_definition.id }
      expect(assigns(:job_definition)).to eq(job_definition)
    end

    it 'shows executions of the job_definition' do
      get :show, params: { id: job_definition.id }
      expect(assigns(:job_executions)).to eq([job_execution])
    end
  end

  describe '#new' do
    it 'assigns a new job_definition' do
      get :new
      expect(assigns(:job_definition)).to be_a_new(Barbeque::JobDefinition)
    end

    context 'with job_definition parameters' do
      let!(:app) { create(:app) }

      it 'pre-fills given parameters' do
        get :new, params: { job_definition: { app_id: app.id } }
        expect(assigns(:job_definition).app_id).to eq(app.id)
      end
    end
  end

  describe '#edit' do
    let!(:job_definition) { create(:job_definition) }

    it 'assigns a requested job_definition' do
      get :edit, params: { id: job_definition.id }
      expect(assigns(:job_definition)).to eq(job_definition)
    end
  end

  describe '#create' do
    let!(:app) { create(:app) }
    let(:attributes) do
      { job: 'AsyncJob', app_id: app.id, command: 'bundle exec rake', description: 'async job' }
    end

    it 'creates a job_definition' do
      expect {
        post :create, params: { job_definition: attributes }
      }.to change(Barbeque::JobDefinition, :count).by(1)
    end

    context 'given use_slack_notification: true and slack_notification_attributes' do
      let(:channel) { '#tech' }
      let(:notify_success) { true }
      let(:failure_notification_text) { '@k0kubun' }
      let(:attributes) do
        {
          job: 'AsyncJob',
          app_id: app.id,
          command: 'bundle exec rake',
          description: 'async job',
          slack_notification_attributes: {
            channel: channel,
            notify_success: notify_success.to_s,
            failure_notification_text: failure_notification_text,
          },
        }
      end

      it 'creates a slack_notification' do
        expect {
          post :create, params: { job_definition: attributes, use_slack_notification: 'true' }
        }.to change(Barbeque::SlackNotification, :count).by(1)
        slack_notification = Barbeque::SlackNotification.last
        expect(Barbeque::JobDefinition.last.slack_notification).to eq(slack_notification)
        expect(slack_notification.channel).to eq(channel)
        expect(slack_notification.notify_success).to eq(notify_success)
        expect(slack_notification.failure_notification_text).to eq(failure_notification_text)
      end
    end

    context 'given duplicated job and app_id' do
      let!(:app) { create(:app) }
      let(:job) { 'DuplicatedJob' }
      let(:attributes) do
        { job: job, app_id: app.id, command: 'bundle exec rake', description: 'duplicated job' }
      end

      before do
        create(:job_definition, app: app, job: job)
      end

      it 'rejects to create a job_definition' do
        expect {
          post :create, params: { job_definition: attributes }
        }.to_not change(Barbeque::JobDefinition, :count)
      end
    end
  end

  describe '#update' do
    let(:old_attributes) { { 'command' => %w[rake], 'description' => 'rake command' } }
    let(:new_attributes) { { 'command' => %w[bundle exec rake], 'description' => 'rake with bundler' } }
    let!(:job_definition) { create(:job_definition, old_attributes) }

    it 'updates a requested app' do
      expect {
        put :update, params: {
          id: job_definition.id,
          job_definition: new_attributes.merge('command' => Shellwords.join(new_attributes['command'])),
        }
      }.to change {
        job_definition.reload.attributes.slice('command', 'description')
      }.from(old_attributes).to(new_attributes)
    end

    context 'given slack_notification_attributes' do
      let(:job_definition) { create(:job_definition, slack_notification: slack_notification) }
      let(:slack_notification) { create(:slack_notification, old_attributes) }
      let(:old_attributes) { { 'channel' => '#tech', 'notify_success' => false, 'failure_notification_text' => '' } }
      let(:new_attributes) { { 'channel' => '#platform', 'notify_success' => true, 'failure_notification_text' => '@k0kubun' } }
      let(:job_attributes) do
        { job: 'AsyncJob', app_id: job_definition.app.id, command: 'bundle exec rake', description: 'async job' }
      end

      it 'updates slack_notification' do
        expect {
          put :update, params: {
            id: job_definition.id,
            job_definition: job_attributes.merge(slack_notification_attributes: new_attributes),
          }
        }.to change {
          job_definition.reload.slack_notification.reload.attributes.slice('channel', 'notify_success', 'failure_notification_text')
        }.from(old_attributes).to(new_attributes)
      end
    end

    context 'given slack_notification_attributes._destroy' do
      let(:job_definition) { create(:job_definition, slack_notification: slack_notification) }
      let(:slack_notification) { create(:slack_notification) }
      let(:job_attributes) do
        { job: 'AsyncJob', app_id: job_definition.app.id, command: 'bundle exec rake', description: 'async job' }
      end

      it 'deletes slack_notification' do
        expect {
          put :update, params: {
            id: job_definition.id,
            job_definition: job_attributes.merge(slack_notification_attributes: { id: slack_notification.id, _destroy: true }),
          }
        }.to change(Barbeque::SlackNotification, :count).by(-1)
      end
    end
  end

  describe '#destroy' do
    let(:job_definition) { create(:job_definition) }

    before do
      create(:job_execution, job_definition: job_definition)
    end

    it 'destroys a requested app and its executions' do
      expect {
        delete :destroy, params: { id: job_definition.id }
      }.to change {
        [Barbeque::JobDefinition.count, Barbeque::JobExecution.count]
      }.from([1, 1]).to([0, 0])
    end

    context 'with SNS subscriptions' do
      let(:sns_client) { double('SNS client') }
      let(:sqs_client) { double('SQS client') }
      let(:sns_subscription) { FactoryBot.create(:sns_subscription, job_definition: job_definition) }
      let(:queue_arn) { 'arn:aws:sqs:ap-northeast-1:012345678901:barbeque-spec' }
      let(:subscription_arn) { 'arn:aws:sns:ap-northeast-1:012345678912:barbeque-spec:01234567-89ab-cdef-0123-456789abcdef' }

      before do
        allow(Barbeque::SNSSubscriptionService).to receive(:sqs_client).and_return(sqs_client)
        allow(Aws::SNS::Client).to receive(:new).with(region: 'ap-northeast-1').and_return(sns_client)

        allow(sqs_client).to receive(:get_queue_attributes).
          with(queue_url: sns_subscription.job_queue.queue_url, attribute_names: ['QueueArn']).
          and_return(Aws::SQS::Types::GetQueueAttributesResult.new(attributes: { 'QueueArn' => queue_arn }))
        allow(sns_client).to receive(:list_subscriptions_by_topic).
          with(topic_arn: sns_subscription.topic_arn).
          and_return(Aws::SNS::Types::ListSubscriptionsByTopicResponse.new(subscriptions: [Aws::SNS::Types::Subscription.new(endpoint: queue_arn, subscription_arn: subscription_arn)]))
      end

      it 'unsubscribes SNS topic' do
        expect(sqs_client).to receive(:set_queue_attributes).with(queue_url: sns_subscription.job_queue.queue_url, attributes: { 'Policy' => '' })
        expect(sns_client).to receive(:unsubscribe).with(subscription_arn: subscription_arn)
        delete :destroy, params: { id: job_definition.id }
        expect(Barbeque::SNSSubscription.all).to be_empty
      end
    end
  end
end
