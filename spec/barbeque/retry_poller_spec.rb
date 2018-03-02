require 'rails_helper'
require 'barbeque/retry_poller'

RSpec.describe Barbeque::RetryPoller do
  let(:job_queue) { create(:job_queue) }
  let(:retry_poller) { described_class.new(job_queue) }
  let(:executor) { double('Barbeque::Executor::Docker') }

  before do
    allow(Barbeque::Executor::Docker).to receive(:new).with({}).and_return(executor)
  end

  describe '#run' do
    context 'when there is a running job retry' do
      let(:job_execution) { create(:job_execution, status: :retried, job_queue: job_queue) }
      let(:job_retry) { create(:job_retry, job_execution: job_execution, status: :running) }

      it 'polls the job retry' do
        expect(executor).to receive(:poll_retry).with(job_retry)
        retry_poller.run
      end
    end
  end
end
