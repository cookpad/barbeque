require 'rails_helper'
require 'barbeque/execution_log'

describe Barbeque::JobExecutionsController do
  routes { Barbeque::Engine.routes }

  describe '#show' do
    let(:job_execution) { create(:job_execution) }
    let(:execution_log) do
      { 'message' => message, 'stdout' => stdout, 'stderr' => stderr }
    end
    let(:message) { ['hello'] }
    let(:stdout)  { 'stdout' }
    let(:stderr)  { 'stderr' }

    before do
      allow(Barbeque::ExecutionLog).to receive(:load).
        with(execution: job_execution).and_return(execution_log)
    end

    it 'shows job definition' do
      get :show, params: { message_id: job_execution.message_id }
      expect(assigns(:job_execution)).to eq(job_execution)
    end

    it 'shows message, stdout, stderr in S3' do
      get :show, params: { message_id: job_execution.message_id }
      expect(assigns(:log)).to eq({ 'message' => message, 'stdout' => stdout, 'stderr' => stderr })
    end

    context 'with id' do
      it 'redirects to job execution' do
        get :show, params: { message_id: job_execution.id }
        expect(response).to redirect_to(job_execution_path(job_execution))
      end
    end
  end

  describe '#retry' do
    let(:job_execution) { create(:job_execution, status: 'failed') }
    let(:retrying_service) { double('MessageEnqueuingService') }
    let(:message) { '["hello"]' }
    let(:result) { double('Aws::SQS::Types::SendMessageResult', message_id: SecureRandom.uuid) }

    before do
      allow(Barbeque::ExecutionLog).to receive(:load).and_return({ 'message' => message })
      allow(retrying_service).to receive(:run).and_return(result)
    end

    it 'enqueues the same message and mark as retried' do
      expect(Barbeque::MessageRetryingService).to receive(:new).with(
        message_id: job_execution.message_id,
      ).and_return(retrying_service)

      expect {
        post :retry, params: { job_execution_message_id: job_execution.message_id }
      }.to change {
        job_execution.reload.status
      }.from('failed').to('retried')
    end

    context 'when execution is already retried' do
      let(:job_execution) { create(:job_execution, status: 'retried') }

      it 'does not retry' do
        expect {
          post :retry, params: { job_execution_message_id: job_execution.message_id }
        }.to raise_error(ActionController::BadRequest)
      end
    end

    context 'when execution is error' do
      let(:job_execution) { create(:job_execution, status: 'error') }

      it 'enqueues the same message and mark as retried' do
        expect(Barbeque::MessageRetryingService).to receive(:new).with(
          message_id: job_execution.message_id,
        ).and_return(retrying_service)

        expect {
          post :retry, params: { job_execution_message_id: job_execution.message_id }
        }.to change {
          job_execution.reload.status
        }.from('error').to('retried')
      end
    end
  end
end
