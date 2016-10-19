require 'rails_helper'
require 'aws-sdk'

describe 'job_retries' do
  let(:result) { JSON.parse(response.body) }
  let(:env) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json' } }

  describe 'POST /v1/job_executions/:job_execution_message_id/retries' do
    let(:message_id) { SecureRandom.uuid }
    let(:send_message_result) { double('Aws::SQS::Types::SendMessageResult', message_id: message_id) }
    let(:job_execution) { create(:job_execution) }
    let(:sqs_client) { double('Aws::SQS::Client') }

    before do
      allow(Barbeque::MessageRetryingService).to receive(:sqs_client).and_return(sqs_client)
    end

    it 'enqueues a message to retry a specified message', :autodoc do
      expect(sqs_client).to receive(:send_message).with(
        queue_url: job_execution.job_queue.queue_url,
        message_body: {
          'Type' => 'JobRetry',
          'RetryMessageId' => job_execution.message_id,
        }.to_json,
        delay_seconds: 0,
      ).and_return(send_message_result)

      post "/v1/job_executions/#{job_execution.message_id}/retries", env: env
      expect(result).to eq({
        'message_id' => message_id,
        'status'     => 'pending',
      })
    end

    context 'given valid delay_seconds' do
      let(:delay_seconds) { 900 }
      let(:params) { { delay_seconds: delay_seconds } }

      it 'enqueues a message with delay' do
        expect(sqs_client).to receive(:send_message).with(
          queue_url: job_execution.job_queue.queue_url,
          message_body: {
            'Type' => 'JobRetry',
            'RetryMessageId' => job_execution.message_id,
          }.to_json,
          delay_seconds: delay_seconds,
        ).and_return(send_message_result)
        post "/v1/job_executions/#{job_execution.message_id}/retries", params: params.to_json, env: env
      end
    end

    context 'given invalid delay_seconds' do
      let(:params) { { delay_seconds: 901 } }

      it 'returns bad request' do
        post "/v1/job_executions/#{job_execution.message_id}/retries", params: params.to_json, env: env
        expect(response).to have_http_status(400)
      end
    end
  end
end
