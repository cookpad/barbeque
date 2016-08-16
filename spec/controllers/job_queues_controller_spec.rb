require 'rails_helper'

describe JobQueuesController do
  describe '#index' do
    let!(:job_queue) { create(:job_queue) }

    it 'shows all job_queues' do
      get :index
      expect(assigns(:job_queues)).to eq([job_queue])
    end
  end

  describe '#show' do
    let!(:job_queue) { create(:job_queue) }

    it 'shows a requested job_queue' do
      get :show, params: { id: job_queue.id }
      expect(assigns(:job_queue)).to eq(job_queue)
    end
  end

  describe '#new' do
    it 'assigns a new job_queue' do
      get :new
      expect(assigns(:job_queue)).to be_a_new(JobQueue)
    end
  end

  describe '#edit' do
    let!(:job_queue) { create(:job_queue) }

    it 'assigns a requested job_queue' do
      get :edit, params: { id: job_queue.id }
      expect(assigns(:job_queue)).to eq(job_queue)
    end
  end

  describe '#create' do
    let(:name) { 'default' }
    let(:queue_name) { JobQueue::SQS_NAME_PREFIX + name }
    let(:queue_url)  { "https://sqs.ap-northeast-1.amazonaws.com/123456789012/#{queue_name}" }
    let(:sqs_client) { double('Aws::SQS::Client', create_queue: create_response) }
    let(:attributes) { { name: name, description: 'default queue' } }
    let(:create_response) { double('Aws::SQS::Types::CreateQueueResult', queue_url: queue_url) }

    before do
      allow(Aws::SQS::Client).to receive(:new).and_return(sqs_client)
    end

    it 'creates a new job_queue' do
      expect {
        post :create, params: { job_queue: attributes }
      }.to change(JobQueue, :count).by(1)
    end

    it 'creates SQS queue' do
      expect(sqs_client).to receive(:create_queue).with(
        queue_name: queue_name,
        attributes: { 'ReceiveMessageWaitTimeSeconds' => JobQueue::SQS_RECEIVE_MESSAGE_WAIT_TIME.to_s },
      )
      post :create, params: { job_queue: attributes }
      expect(JobQueue.last.queue_url).to eq(queue_url)
    end

    context 'given duplicated name' do
      let(:name) { 'duplicated_name' }
      let(:attributes) { { name: name, description: 'duplicated queue' } }

      before do
        create(:job_queue, name: name)
      end

      it 'rejects to create a job_queue' do
        expect {
          post :create, params: { job_queue: attributes }
        }.to_not change(JobQueue, :count)
      end
    end

    context 'given invalid name' do
      let(:attributes) { { name: 'invalid name', description: 'default queue' } }

      it 'rejects to create a job_queue' do
        expect {
          post :create, params: { job_queue: attributes }
        }.to_not change(JobQueue, :count)
      end

      it 'does not create SQS queue' do
        expect(sqs_client).to_not receive(:create_queue)
        post :create, params: { job_queue: attributes }
      end
    end
  end

  describe '#update' do
    let(:old_description) { 'old description' }
    let(:new_description) { 'new description' }
    let!(:job_queue) { create(:job_queue, description: old_description) }

    it 'updates a requested job_queue' do
      expect {
        put :update, params: { id: job_queue.id, job_queue: { description: new_description } }
      }.to change {
        job_queue.reload.description
      }.from(old_description).to(new_description)
    end
  end

  describe '#destroy' do
    let!(:job_queue) { create(:job_queue) }

    it 'destroys a requested job_queue' do
      expect {
        delete :destroy, params: { id: job_queue.id }
      }.to change(JobQueue, :count).by(-1)
    end
  end
end
