require 'rails_helper'

describe 'job_executions' do
  let(:result) { JSON.parse(response.body) }
  let(:env) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json' } }

  describe 'GET /v1/job_executions/:message_id' do
    context 'when job_execution exists' do
      let(:status) { 'success' }
      let(:job_execution) { create(:job_execution, status: status) }

      it 'shows a status of a job_execution', :autodoc do
        get "/v1/job_executions/#{job_execution.message_id}", env: env
        expect(result).to match({
          'message_id' => job_execution.message_id,
          'status'     => status,
        })
      end
    end

    context 'when job_execution does not exist' do
      let(:message_id) { SecureRandom.uuid }

      it 'returns pending as status' do
        get "/v1/job_executions/#{message_id}", env: env
        expect(result).to match({
          'message_id' => message_id,
          'status'     => 'pending',
        })
      end
    end
  end

  describe 'POST /v2/job_executions' do
    let(:enqueuing_service) { double('Barbeque::MessageEnqueuingService') }
    let(:message_id) { SecureRandom.uuid }
    let(:job_queue)   { create(:job_queue) }
    let(:queue_name)  { job_queue.name }
    let(:job)         { 'NotifyAuthor' }
    let(:message)     { { 'recipe_id' => 1 } }
    let(:application) { 'blog' }
    let(:params) do
      {
        application: application,
        job:         job,
        queue:       queue_name,
        message:     message,
      }
    end

    it 'enqueues a job execution', :autodoc do
      expect(Barbeque::MessageEnqueuingService).to receive(:new).with(
        application: application,
        job:     job,
        queue:   job_queue.name,
        message: ActionController::Parameters.new(message),
      ).and_return(enqueuing_service)
      expect(enqueuing_service).to receive(:run).and_return(message_id)

      post '/v2/job_executions', params: params.to_json, env: env
      expect(response).to have_http_status(201)
      expect(result).to eq({
        'message_id' => message_id,
        'status'     => 'pending',
      })
    end

    context 'when specified queue does not exist' do
      let(:queue_name) { 'non-existent queue name' }

      it 'returns 404' do
        post '/v2/job_executions', params: params.to_json, env: env
        expect(response).to have_http_status(404)
      end
    end
  end
end
