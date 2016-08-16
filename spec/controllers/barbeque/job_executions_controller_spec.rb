require 'rails_helper'
require 'execution_log'

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
      allow(ExecutionLog).to receive(:load).
        with(execution: job_execution).and_return(execution_log)
    end

    it 'shows job definition' do
      get :show, params: { id: job_execution.id }
      expect(assigns(:job_execution)).to eq(job_execution)
    end

    it 'shows message, stdout, stderr in S3' do
      get :show, params: { id: job_execution.id }
      expect(assigns(:message)).to eq(message)
      expect(assigns(:stdout)).to eq(stdout)
      expect(assigns(:stderr)).to eq(stderr)
    end
  end

  describe '#retry' do
    let(:job_execution) { create(:job_execution, status: 'failed') }
    let(:retrying_service) { double('MessageEnqueuingService') }
    let(:message) { '["hello"]' }
    let(:result) { double('Aws::SQS::Types::SendMessageResult', message_id: SecureRandom.uuid) }

    before do
      allow(ExecutionLog).to receive(:load).and_return({ 'message' => message })
      allow(retrying_service).to receive(:run).and_return(result)
    end

    it 'enqueues the same message and mark as retried' do
      expect(Barbeque::MessageRetryingService).to receive(:new).with(
        message_id: job_execution.message_id,
      ).and_return(retrying_service)

      expect {
        post :retry, params: { job_execution_id: job_execution.id }
      }.to change {
        job_execution.reload.status
      }.from('failed').to('retried')
    end

    context 'when execution is already retried' do
      let(:job_execution) { create(:job_execution, status: 'retried') }

      it 'does not retry' do
        expect {
          post :retry, params: { job_execution_id: job_execution.id }
        }.to raise_error(ActionController::BadRequest)
      end
    end
  end
end
