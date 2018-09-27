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
        expect(result).to eq(
          'message_id' => job_execution.message_id,
          'status'     => status,
          'id'         => job_execution.id,
        )
      end

      context 'when requested with fields=html_url', :autodoc do
        it 'shows url to job_execution' do
          get "/v1/job_executions/#{job_execution.message_id}?fields=__default__,html_url", env: env
          expect(result).to eq(
            'message_id' => job_execution.message_id,
            'status'     => status,
            'id'         => job_execution.id,
            'html_url'   => "http://www.example.com/job_executions/#{job_execution.message_id}",
          )
        end
      end

      context 'when requested with fields=message', :autodoc do
        let(:execution_log) do
          { 'message' => message, 'stdout' => '', 'stderr' => '' }
        end
        let(:message) do
          { 'recipe_id' => 12345 }
        end

        before do
          allow(Barbeque::ExecutionLog).to receive(:load).with(execution: job_execution).and_return(execution_log)
        end

        it 'returns message of the job_execution' do
          get "/v1/job_executions/#{job_execution.message_id}?fields=__default__,message", env: env
          expect(result).to eq(
            'message_id' => job_execution.message_id,
            'status' => status,
            'id' => job_execution.id,
            'message' => message,
          )
        end
      end
    end

    context 'when job_execution does not exist' do
      let(:message_id) { SecureRandom.uuid }

      it 'returns pending as status' do
        get "/v1/job_executions/#{message_id}", env: env
        expect(result).to eq(
          'message_id' => message_id,
          'status'     => 'pending',
          'id'         => nil,
        )
      end

      context 'when requested with fields=html_url' do
        it "doesn't shows url" do
          get "/v1/job_executions/#{message_id}?fields=__default__,html_url", env: env
          expect(result).to eq(
            'message_id' => message_id,
            'status'     => 'pending',
            'id'         => nil,
            'html_url'   => nil,
          )
        end
      end

      context 'when requested with fields=message' do
        it "returns nil message" do
          get "/v1/job_executions/#{message_id}?fields=__default__,message", env: env
          expect(result).to eq(
            'message_id' => message_id,
            'status' => 'pending',
            'id' => nil,
            'message' => nil,
          )
        end
      end
    end

    context 'when database maintenance mode' do
      around do |example|
        env = ENV.to_h
        ENV['BARBEQUE_DATABASE_MAINTENANCE'] = '1'
        ENV['AWS_REGION'] = 'ap-northeast-1'
        ENV['AWS_ACCOUNT_ID'] = '123456789012'
        example.run
        ENV.replace(env)
      end

      let!(:job_execution) { FactoryBot.create(:job_execution) }

      context 'when database is available' do
        it 'returns execution status' do
          get "/v1/job_executions/#{job_execution.message_id}", env: env
          expect(response).to have_http_status(200)
          expect(result).to eq(
            'message_id' => job_execution.message_id,
            'status' => job_execution.status,
            'id' => job_execution.id,
          )
        end
      end

      context 'when database is unavailable', :autodoc do
        before do
          allow_any_instance_of(Mysql2::Client).to receive(:query).and_raise(Mysql2::Error::ConnectionError.new("Can't connect to MySQL server"))
        end

        it 'returns error message' do
          get "/v1/job_executions/#{job_execution.message_id}", env: env
          expect(response).to have_http_status(503)
          expect(result).to match(
            'message' => a_kind_of(String),
          )
        end
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
        delay_seconds: nil,
      ).and_return(enqueuing_service)
      expect(enqueuing_service).to receive(:run).and_return(message_id)

      post '/v2/job_executions', params: params.to_json, env: env
      expect(response).to have_http_status(201)
      expect(result).to eq({
        'message_id' => message_id,
        'status'     => 'pending',
        'id'         => nil,
      })
    end

    context 'when specified queue does not exist' do
      let(:queue_name) { 'non-existent queue name' }

      it 'returns 404' do
        post '/v2/job_executions', params: params.to_json, env: env
        expect(response).to have_http_status(404)
      end
    end

    context 'when requested with fields=html_url' do
      it "doesn't shows url" do
        get "/v1/job_executions/#{message_id}?fields=__default__,html_url", env: env
        expect(result).to eq(
          'message_id' => message_id,
          'status'     => 'pending',
          'id'         => nil,
          'html_url'   => nil,
        )
      end
    end

    context 'when BARBEQUE_VERIFY_ENQUEUED_JOBS is enabled' do
      before do
        stub_const('Barbeque::MessageEnqueuingService::VERIFY_ENQUEUED_JOBS', '1')
      end

      context 'without valid job definition' do
        it 'returns 400' do
          post '/v2/job_executions', params: params.to_json, env: env
          expect(response).to have_http_status(400)
          expect(result).to match('error' => String)
        end
      end

      context 'with valid job definition' do
        before do
          app = FactoryBot.create(:app, name: application)
          FactoryBot.create(:job_definition, app: app, job: job)
        end

        it 'enqueues a job execution' do
          expect(Barbeque::MessageEnqueuingService).to receive(:new).with(
            application: application,
            job: job,
            queue: job_queue.name,
            message: ActionController::Parameters.new(message),
            delay_seconds: nil,
          ).and_return(enqueuing_service)
          expect(enqueuing_service).to receive(:run).and_return(message_id)

          post '/v2/job_executions', params: params.to_json, env: env
          expect(response).to have_http_status(201)
          expect(result).to eq(
            'message_id' => message_id,
            'status' => 'pending',
            'id' => nil,
          )
        end
      end
    end

    context 'with delay_seconds' do
      let(:delay_seconds) { 300 }

      before do
        params[:delay_seconds] = delay_seconds
      end

      it 'enqueues a job execution with delay_seconds', :autodoc do
        expect(Barbeque::MessageEnqueuingService).to receive(:new).with(
          application: application,
          job:     job,
          queue:   job_queue.name,
          message: ActionController::Parameters.new(message),
          delay_seconds: delay_seconds,
        ).and_return(enqueuing_service)
        expect(enqueuing_service).to receive(:run).and_return(message_id)

        post '/v2/job_executions', params: params.to_json, env: env
        expect(response).to have_http_status(201)
        expect(result).to eq({
          'message_id' => message_id,
          'status'     => 'pending',
          'id'         => nil,
        })
      end
    end
  end
end
