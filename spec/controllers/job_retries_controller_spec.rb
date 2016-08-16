require 'rails_helper'
require 'execution_log'

describe JobRetriesController do
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
      allow(ExecutionLog).to receive(:load).with(execution: job_execution).and_return(execution_log)
      allow(ExecutionLog).to receive(:load).with(execution: job_retry).and_return(retry_log)
    end

    it 'shows job retry' do
      get :show, params: { job_execution_id: job_execution.id, id: job_retry.id }
      expect(assigns(:job_retry)).to eq(job_retry)
    end

    it 'shows message, stdout, stderr in S3' do
      get :show, params: { job_execution_id: job_execution.id, id: job_retry.id }
      expect(assigns(:message)).to eq(message)
      expect(assigns(:stdout)).to eq(stdout)
      expect(assigns(:stderr)).to eq(stderr)
    end
  end
end
