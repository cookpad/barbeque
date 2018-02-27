require 'rails_helper'
require 'barbeque/execution_poller'

RSpec.describe Barbeque::ExecutionPoller do
  let(:job_queue) { create(:job_queue) }
  let(:execution_poller) { described_class.new(job_queue) }
  let(:executor) { double('Barbeque::Executor::Docker') }

  before do
    allow(Barbeque::Executor::Docker).to receive(:new).with({}).and_return(executor)
  end

  describe '#run' do
    context 'when there is a running job execution' do
      let(:job_execution) { create(:job_execution, status: :running, job_queue: job_queue) }

      it 'polls the job execution' do
        expect(executor).to receive(:poll_execution).with(job_execution)
        execution_poller.run
      end
    end
  end
end
