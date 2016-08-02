require 'rails_helper'
require 'job_executor/storage'

describe JobExecutor::Storage do
  let(:job_execution) { create(:job_execution, status: status) }
  let(:s3_client) { double('Aws::S3::Client') }
  let(:s3_object) do
    Aws::S3::Types::GetObjectOutput.new(body: StringIO.new(JSON.dump(s3_log)))
  end
  let(:s3_log) do
    { message: message, stdout: stdout, stderr: stderr }
  end
  let(:message) { ['hello'] }
  let(:stdout)  { 'stdout' }
  let(:stderr)  { 'stderr' }

  before do
    allow(Aws::S3::Client).to receive(:new).and_return(s3_client)
  end

  describe '.fetch' do
    context 'when job_execution is finished' do
      let(:status) { 'success' }

      before do
        allow(s3_client).to receive(:get_object).with(
          key: File.join(job_execution.app.name, job_execution.job_definition.job, job_execution.message_id),
          bucket: 'barbeque',
        ).and_return(s3_object)
      end

      it 'fetches log from S3 for the job_execution' do
        expect(JobExecutor::Storage.load(execution: job_execution)).to eq({
          'message' => message,
          'stdout'  => stdout,
          'stderr'  => stderr,
        })
      end
    end

    context 'when job_execution is pending' do
      let(:status) { 'pending' }

      before do
        key = File.join(job_execution.app.name, job_execution.job_definition.job, job_execution.message_id)
        allow(s3_client).to receive(:get_object).with(
          key: key,
          bucket: 'barbeque',
        ).and_raise(Aws::S3::Errors::NoSuchKey.new(key, 'The specified key does not exist.'))
      end

      it 'returns empty hash' do
        expect(JobExecutor::Storage.load(execution: job_execution)).to eq({})
      end
    end

    context 'when job_retry is given' do
      let(:job_retry) { create(:job_retry, job_execution: job_execution) }
      let(:status) { 'success' }

      before do
        allow(s3_client).to receive(:get_object).with(
          key: File.join(job_execution.app.name, job_execution.job_definition.job, job_retry.message_id),
          bucket: 'barbeque',
        ).and_return(s3_object)
      end

      it 'fetches log from S3 for the job_retry' do
        expect(JobExecutor::Storage.load(execution: job_retry)).to eq({
          'message' => message,
          'stdout'  => stdout,
          'stderr'  => stderr,
        })
      end
    end
  end
end
