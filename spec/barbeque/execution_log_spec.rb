require 'rails_helper'
require 'barbeque/execution_log'

describe Barbeque::ExecutionLog do
  let(:job_execution) { create(:job_execution, status: status) }
  let(:s3_client) { double('Aws::S3::Client') }
  let(:legacy_s3_object) do
    Aws::S3::Types::GetObjectOutput.new(body: StringIO.new(JSON.dump(legacy_s3_log)))
  end
  let(:legacy_s3_log) do
    { message: message, stdout: stdout, stderr: stderr }
  end
  let(:message) { ['hello'] }
  let(:stdout)  { 'stdout' }
  let(:stderr)  { 'stderr' }

  before do
    allow(Barbeque::ExecutionLog).to receive(:s3_client).and_return(s3_client)
  end

  describe '.fetch' do
    def make_s3_object(content)
      Aws::S3::Types::GetObjectOutput.new(body: StringIO.new(content))
    end

    context 'when job_execution is finished' do
      let(:status) { 'success' }

      before do
        allow(s3_client).to receive(:get_object).with(
          key: "#{job_execution.app.name}/#{job_execution.job_definition.job}/#{job_execution.message_id}/message.json",
          bucket: 'barbeque',
        ).and_return(make_s3_object(message.to_json))
        allow(s3_client).to receive(:get_object).with(
          key: "#{job_execution.app.name}/#{job_execution.job_definition.job}/#{job_execution.message_id}/stdout.txt",
          bucket: 'barbeque',
        ).and_return(make_s3_object(stdout))
        allow(s3_client).to receive(:get_object).with(
          key: "#{job_execution.app.name}/#{job_execution.job_definition.job}/#{job_execution.message_id}/stderr.txt",
          bucket: 'barbeque',
        ).and_return(make_s3_object(stderr))
      end

      it 'fetches log from S3 for the job_execution' do
        expect(Barbeque::ExecutionLog.load(execution: job_execution)).to eq({
          'message' => message.to_json,
          'stdout'  => stdout,
          'stderr'  => stderr,
        })
      end

      context 'with legacy format' do
        before do
          allow(s3_client).to receive(:get_object).with(
            key: "#{job_execution.app.name}/#{job_execution.job_definition.job}/#{job_execution.message_id}/message.json",
            bucket: 'barbeque',
          ).and_raise(Aws::S3::Errors::NoSuchKey.new(nil, 'The specified key does not exist.'))
          allow(s3_client).to receive(:get_object).with(
            key: "#{job_execution.app.name}/#{job_execution.job_definition.job}/#{job_execution.message_id}/stdout.txt",
            bucket: 'barbeque',
          ).and_raise(Aws::S3::Errors::NoSuchKey.new(nil, 'The specified key does not exist.'))
          allow(s3_client).to receive(:get_object).with(
            key: "#{job_execution.app.name}/#{job_execution.job_definition.job}/#{job_execution.message_id}/stderr.txt",
            bucket: 'barbeque',
          ).and_raise(Aws::S3::Errors::NoSuchKey.new(nil, 'The specified key does not exist.'))
          allow(s3_client).to receive(:get_object).with(
            key: "#{job_execution.app.name}/#{job_execution.job_definition.job}/#{job_execution.message_id}",
            bucket: 'barbeque',
          ).and_return(legacy_s3_object)
        end

        it 'fetches legacy log from S3 for the job_execution' do
          expect(Barbeque::ExecutionLog.load(execution: job_execution)).to eq({
            'message' => message,
            'stdout'  => stdout,
            'stderr'  => stderr,
          })
        end
      end
    end

    context 'when job_execution is pending' do
      let(:status) { 'pending' }

      before do
        key = "#{job_execution.app.name}/#{job_execution.job_definition.job}/#{job_execution.message_id}"
        allow(s3_client).to receive(:get_object).with(
          key: key,
          bucket: 'barbeque',
        ).and_raise(Aws::S3::Errors::NoSuchKey.new(key, 'The specified key does not exist.'))
      end

      it 'returns empty hash' do
        expect(Barbeque::ExecutionLog.load(execution: job_execution)).to eq({})
      end
    end

    context 'when job_retry is given' do
      let(:job_retry) { create(:job_retry, job_execution: job_execution) }
      let(:status) { 'success' }

      before do
        allow(s3_client).to receive(:get_object).with(
          key: "#{job_execution.app.name}/#{job_execution.job_definition.job}/#{job_retry.message_id}/message.json",
          bucket: 'barbeque',
          ).and_raise(Aws::S3::Errors::NoSuchKey.new(nil, 'The specified key does not exist.'))
        allow(s3_client).to receive(:get_object).with(
          key: "#{job_execution.app.name}/#{job_execution.job_definition.job}/#{job_retry.message_id}/stdout.txt",
          bucket: 'barbeque',
        ).and_return(make_s3_object(stdout))
        allow(s3_client).to receive(:get_object).with(
          key: "#{job_execution.app.name}/#{job_execution.job_definition.job}/#{job_retry.message_id}/stderr.txt",
          bucket: 'barbeque',
        ).and_return(make_s3_object(stderr))
      end

      it 'fetches log from S3 for the job_retry' do
        expect(Barbeque::ExecutionLog.load(execution: job_retry)).to eq({
          'message' => nil,
          'stdout'  => stdout,
          'stderr'  => stderr,
        })
      end

      context 'with legacy format' do
        before do
          allow(s3_client).to receive(:get_object).with(
            key: "#{job_execution.app.name}/#{job_execution.job_definition.job}/#{job_retry.message_id}/message.json",
            bucket: 'barbeque',
          ).and_raise(Aws::S3::Errors::NoSuchKey.new(nil, 'The specified key does not exist.'))
          allow(s3_client).to receive(:get_object).with(
            key: "#{job_execution.app.name}/#{job_execution.job_definition.job}/#{job_retry.message_id}/stdout.txt",
            bucket: 'barbeque',
          ).and_raise(Aws::S3::Errors::NoSuchKey.new(nil, 'The specified key does not exist.'))
          allow(s3_client).to receive(:get_object).with(
            key: "#{job_execution.app.name}/#{job_execution.job_definition.job}/#{job_retry.message_id}/stderr.txt",
            bucket: 'barbeque',
          ).and_raise(Aws::S3::Errors::NoSuchKey.new(nil, 'The specified key does not exist.'))
          allow(s3_client).to receive(:get_object).with(
            key: "#{job_execution.app.name}/#{job_execution.job_definition.job}/#{job_retry.message_id}",
            bucket: 'barbeque',
          ).and_return(legacy_s3_object)
        end

        it 'fetches legacy log from S3 for the job_retry' do
          expect(Barbeque::ExecutionLog.load(execution: job_retry)).to eq({
            'message' => message,
            'stdout'  => stdout,
            'stderr'  => stderr,
          })
        end
      end
    end
  end
end
