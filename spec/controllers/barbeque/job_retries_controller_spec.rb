require 'rails_helper'
require 'barbeque/execution_log'

describe Barbeque::JobRetriesController do
  routes { Barbeque::Engine.routes }

  describe '#show' do
    let(:job_retry)     { create(:job_retry, job_execution: job_execution) }
    let(:job_execution) { create(:job_execution) }
    let(:execution_log) do
      { 'message' => message }
    end
    let(:retry_log) do
      { 'stdout' => stdout, 'stderr' => stderr }
    end
    let(:message) { ['hello'] }
    let(:stdout)  { 'stdout' }
    let(:stderr)  { 'stderr' }

    before do
      allow(Barbeque::ExecutionLog).to receive(:load).with(execution: job_execution).and_return(execution_log)
      allow(Barbeque::ExecutionLog).to receive(:load).with(execution: job_retry).and_return(retry_log)
    end

    it 'shows job retry' do
      get :show, params: { job_execution_message_id: job_execution.message_id, id: job_retry.id }
      expect(assigns(:job_retry)).to eq(job_retry)
    end

    it 'shows message, stdout, stderr in S3' do
      get :show, params: { job_execution_message_id: job_execution.message_id, id: job_retry.id }
      expect(assigns(:execution_log)).to eq(execution_log)
      expect(assigns(:retry_log)).to eq(retry_log)
    end

    context 'when job_execution id is given' do
      it "redirects to job_retry with job_execution's message id" do
        get :show, params: { job_execution_message_id: job_execution.id, id: job_retry.id }
        expect(response).to redirect_to(job_execution_job_retry_path(job_execution, job_retry))
      end
    end
  end
end
