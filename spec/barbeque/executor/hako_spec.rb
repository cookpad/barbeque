require 'rails_helper'
require 'barbeque/executor/hako'

describe Barbeque::Executor::Hako do
  let(:hako_directory) { '.' }
  let(:hako_env) { { 'AWS_REGION' => 'ap-northeast-1' } }
  let(:command) { ['rake', 'test'] }
  let(:executor) do
    described_class.new(
      hako_dir: hako_directory,
      hako_env: hako_env,
      definition_dir: '/yamls',
      oneshot_notification_prefix: 's3://barbeque/task_statuses?region=ap-northeast-1',
    )
  end
  let(:app_name) { 'dummy' }
  let(:app) { FactoryBot.create(:app, docker_image: app_name) }
  let(:job_definition) { FactoryBot.create(:job_definition, app: app, command: command) }
  let(:job_execution) { FactoryBot.create(:job_execution, job_definition: job_definition, status: :pending) }
  let(:envs) { { 'FOO' => 'BAR' } }
  let(:task_arn) { 'arn:aws:ecs:ap-northeast-1:012345678901:task/01234567-89ab-cdef-0123-456789abcdef' }
  let(:sqs_client) { instance_double(Aws::SQS::Client) }

  let(:s3_client) { double('Aws::S3::Client') }
  let(:stopped_info) do
    {
      'detail-type' => 'ECS Task State Change',
      'detail' => {
        'containers' => [
          {
            'exitCode': 0,
            'lastStatus': 'STOPPED',
            'name': 'app',
          }
        ],
        'stoppedAt' => '2017-06-20T07:29:53.695Z',
      },
    }
  end
  let(:s3_key) { "task_statuses/#{task_arn}/stopped.json" }

  around do |example|
    original = ENV['BARBEQUE_HOST']
    ENV['BARBEQUE_HOST'] = 'https://barbeque'
    example.run
    ENV['BARBEQUE_HOST'] = original
  end

  before do
    allow(Barbeque::MessageRetryingService).to receive(:sqs_client).and_return(sqs_client)
  end

  describe 'job_execution' do
    describe '#start_execution' do
      let(:status) { double('Process::Status', success?: true) }
      let(:stdout) { JSON.dump(cluster: 'barbeque', task_arn: task_arn) }
      let(:stderr) { '' }

      before do
        allow(File).to receive(:readable?).with("/yamls/#{app_name}.jsonnet").and_return(false)
        allow(File).to receive(:readable?).with("/yamls/#{app_name}.yml").and_return(true)
        expect(Open3).to receive(:capture3).with(
          hako_env,
          'bundle', 'exec', 'hako', 'oneshot', '--no-wait', '--tag', 'latest',
          '--env=FOO=BAR', "/yamls/#{app_name}.yml", '--', *command,
          chdir: hako_directory,
        ).and_return([stdout, stderr, status])
      end

      it 'starts hako oneshot command within HAKO_DIR' do
        expect(Barbeque::ExecutionLog).to receive(:try_save_stdout_and_stderr).with(job_execution, stdout, stderr)
        expect(Barbeque::EcsHakoTask.count).to eq(0)
        executor.start_execution(job_execution, envs)
        expect(Barbeque::EcsHakoTask.where(message_id: job_execution.message_id, cluster: 'barbeque', task_arn: task_arn)).to be_exists
      end

      it 'sets running status' do
        expect(job_execution).to be_pending
        expect(Barbeque::ExecutionLog).to receive(:try_save_stdout_and_stderr).with(job_execution, stdout, stderr)
        executor.start_execution(job_execution, envs)
        job_execution.reload
        expect(job_execution).to be_running
      end

      context 'when hako oneshot fails' do
        before do
          expect(status).to receive(:success?).and_return(false)
        end

        it 'sets failed status' do
          expect(Barbeque::ExecutionLog).to receive(:try_save_stdout_and_stderr).with(job_execution, stdout, stderr)
          executor.start_execution(job_execution, envs)
          job_execution.reload
          expect(job_execution).to be_failed
          expect(Barbeque::EcsHakoTask.count).to eq(0)
        end

        context 'with retry_config' do
          before do
            FactoryBot.create(:retry_config, job_definition: job_definition)
          end

          it 'performs retry' do
            expect(Barbeque::ExecutionLog).to receive(:try_save_stdout_and_stderr).with(job_execution, stdout, stderr)
            expect(Barbeque::MessageRetryingService.sqs_client).to receive(:send_message).with(queue_url: a_kind_of(String), message_body: a_kind_of(String), delay_seconds: a_kind_of(Integer))
            executor.start_execution(job_execution, envs)
            job_execution.reload
            expect(job_execution).to be_retried
            expect(Barbeque::EcsHakoTask.count).to eq(0)
          end
        end
      end

      context 'when hako generates malformed JSON' do
        let(:stdout) { 'not-a-json-format' }

        it 'raises error' do
          expect { executor.start_execution(job_execution, envs) }.to raise_error(Barbeque::Executor::Hako::HakoCommandError)
          expect(Barbeque::EcsHakoTask.count).to eq(0)
        end
      end

      context 'when S3 returns error' do
        let(:execution_log_s3_client) { double('Aws::S3::Client') }

        before do
          allow(Barbeque::ExecutionLog).to receive(:s3_client).and_return(execution_log_s3_client)
          expect(execution_log_s3_client).to receive(:put_object).and_raise(Aws::S3::Errors::InternalError.new(nil, 'We encountered an internal error. Please try again.'))
        end

        it "doesn't fail job execution" do
          expect(Barbeque::ExceptionHandler).to receive(:handle_exception).with(a_kind_of(Aws::S3::Errors::InternalError))
          executor.start_execution(job_execution, envs)
          expect(Barbeque::EcsHakoTask.where(message_id: job_execution.message_id, cluster: 'barbeque', task_arn: task_arn)).to be_exists
        end
      end
    end

    describe '#poll_execution' do
      before do
        Barbeque::EcsHakoTask.create!(message_id: job_execution.message_id, cluster: 'barbeque', task_arn: task_arn)
        allow(executor.hako_s3_client).to receive(:s3_client).and_return(s3_client)
        job_execution.update!(status: :running)
      end

      context 'when job succeeds' do
        before do
          allow(s3_client).to receive(:get_object).with(bucket: 'barbeque', key: s3_key).and_return(Aws::S3::Types::GetObjectOutput.new(body: StringIO.new(JSON.dump(stopped_info))))
        end

        it 'sets success status' do
          expect(job_execution).to be_running
          executor.poll_execution(job_execution)
          job_execution.reload
          expect(job_execution).to be_success
          expect(job_execution.finished_at).to_not be_nil
        end

        context 'when successful slack_notification is configured' do
          let(:slack_client) { double('Barbeque::SlackClient') }
          let(:slack_notification) { FactoryBot.create(:slack_notification, notify_success: true) }

          before do
            job_execution.job_definition.update!(slack_notification: slack_notification)
            allow(Barbeque::SlackClient).to receive(:new).with(slack_notification.channel).and_return(slack_client)
          end

          it 'sends slack notification' do
            expect(slack_client).to receive(:notify_success)
            executor.poll_execution(job_execution)
          end
        end
      end

      context 'when job is running' do
        before do
          allow(s3_client).to receive(:get_object).with(bucket: 'barbeque', key: s3_key).and_raise(Aws::S3::Errors::NoSuchKey.new(nil, 'no such key'))
        end

        it 'does nothing' do
          expect(job_execution).to be_running
          executor.poll_execution(job_execution)
          job_execution.reload
          expect(job_execution).to be_running
        end
      end

      context 'when job fails' do
        before do
          stopped_info['detail']['containers'][0]['exitCode'] = 1
          allow(s3_client).to receive(:get_object).with(bucket: 'barbeque', key: s3_key).and_return(Aws::S3::Types::GetObjectOutput.new(body: StringIO.new(JSON.dump(stopped_info))))
        end

        it 'sets failed status' do
          expect(job_execution).to be_running
          executor.poll_execution(job_execution)
          job_execution.reload
          expect(job_execution).to be_failed
          expect(job_execution.finished_at).to_not be_nil
        end

        context 'when slack_notification is configured' do
          let(:slack_client) { double('Barbeque::SlackClient') }
          let(:slack_notification) { FactoryBot.create(:slack_notification, notify_success: false) }

          before do
            job_execution.job_definition.update!(slack_notification: slack_notification)
            allow(Barbeque::SlackClient).to receive(:new).with(slack_notification.channel).and_return(slack_client)
          end

          it 'sends slack notification' do
            expect(slack_client).to receive(:notify_failure)
            executor.poll_execution(job_execution)
          end
        end

        context 'with retry_config' do
          before do
            FactoryBot.create(:retry_config, job_definition: job_definition)
          end

          it 'performs retry' do
            expect(job_execution).to be_running
            expect(Barbeque::MessageRetryingService.sqs_client).to receive(:send_message).with(queue_url: a_kind_of(String), message_body: a_kind_of(String), delay_seconds: a_kind_of(Integer))
            executor.poll_execution(job_execution)
            job_execution.reload
            expect(job_execution).to be_retried
          end
        end
      end
    end
  end

  describe 'job_retry' do
    let(:job_retry) { FactoryBot.create(:job_retry, job_execution: job_execution, status: :pending) }
    let(:status) { double('Process::Status', success?: true) }
    let(:stdout) { JSON.dump(cluster: 'barbeque', task_arn: task_arn) }
    let(:stderr) { '' }

    before do
      job_execution.update!(status: :failed)
    end

    describe '#start_retry' do
      before do
        allow(File).to receive(:readable?).with("/yamls/#{app_name}.jsonnet").and_return(false)
        allow(File).to receive(:readable?).with("/yamls/#{app_name}.yml").and_return(true)
        expect(Open3).to receive(:capture3).with(
          hako_env,
          'bundle', 'exec', 'hako', 'oneshot', '--no-wait', '--tag', 'latest',
          '--env=FOO=BAR', "/yamls/#{app_name}.yml", '--', *command,
          chdir: hako_directory,
        ).and_return([stdout, stderr, status])
      end

      it 'starts hako oneshot command' do
        expect(Barbeque::ExecutionLog).to receive(:try_save_stdout_and_stderr).with(job_retry, stdout, stderr)
        expect(Barbeque::EcsHakoTask.count).to eq(0)
        executor.start_retry(job_retry, envs)
        expect(Barbeque::EcsHakoTask.where(message_id: job_retry.message_id, cluster: 'barbeque', task_arn: task_arn)).to be_exists
      end

      it 'sets running status' do
        expect(Barbeque::ExecutionLog).to receive(:try_save_stdout_and_stderr).with(job_retry, stdout, stderr)
        expect(job_retry).to be_pending
        expect(job_execution).to be_failed
        executor.start_retry(job_retry, envs)
        job_retry.reload
        job_execution.reload
        expect(job_retry).to be_running
        expect(job_execution).to be_retried
      end

      context 'when hako oneshot fails' do
        before do
          expect(status).to receive(:success?).and_return(false)
        end

        it 'sets failed status' do
          expect(Barbeque::ExecutionLog).to receive(:try_save_stdout_and_stderr).with(job_retry, stdout, stderr)
          expect(job_retry).to be_pending
          expect(job_execution).to be_failed
          executor.start_retry(job_retry, envs)
          job_retry.reload
          job_execution.reload
          expect(job_retry).to be_failed
          expect(job_execution).to be_failed
        end

        context 'with retry_config' do
          before do
            FactoryBot.create(:retry_config, job_definition: job_definition)
          end

          it 'performs retry' do
            expect(Barbeque::ExecutionLog).to receive(:try_save_stdout_and_stderr).with(job_retry, stdout, stderr)
            expect(Barbeque::MessageRetryingService.sqs_client).to receive(:send_message).with(queue_url: a_kind_of(String), message_body: a_kind_of(String), delay_seconds: a_kind_of(Integer))
            expect(job_retry).to be_pending
            expect(job_execution).to be_failed
            executor.start_retry(job_retry, envs)
            job_retry.reload
            job_execution.reload
            expect(job_retry).to be_failed
            expect(job_execution).to be_retried
          end
        end
      end

      context 'when hako generates malformed JSON' do
        let(:stdout) { 'not-a-json-format' }

        it 'raises error' do
          expect { executor.start_retry(job_retry, envs) }.to raise_error(Barbeque::Executor::Hako::HakoCommandError)
        end
      end
    end

    describe '#poll_retry' do
      before do
        Barbeque::EcsHakoTask.create!(message_id: job_retry.message_id, cluster: 'barbeque', task_arn: task_arn)
        allow(executor.hako_s3_client).to receive(:s3_client).and_return(s3_client)
        job_retry.update!(status: :running)
        job_execution.update!(status: :retried)
      end

      context 'when retried job succeeds' do
        before do
          allow(s3_client).to receive(:get_object).with(bucket: 'barbeque', key: s3_key).and_return(Aws::S3::Types::GetObjectOutput.new(body: StringIO.new(JSON.dump(stopped_info))))
        end

        it 'sets success status' do
          expect(job_retry).to be_running
          expect(job_execution).to be_retried
          executor.poll_retry(job_retry)
          job_retry.reload
          job_execution.reload
          expect(job_retry).to be_success
          expect(job_execution).to be_success
        end

        context 'when successful slack_notification is configured' do
          let(:slack_client) { double('Barbeque::SlackClient') }
          let(:slack_notification) { FactoryBot.create(:slack_notification, notify_success: true) }

          before do
            job_execution.job_definition.update!(slack_notification: slack_notification)
            allow(Barbeque::SlackClient).to receive(:new).with(slack_notification.channel).and_return(slack_client)
          end

          it 'sends slack notification' do
            expect(slack_client).to receive(:notify_success)
            executor.poll_retry(job_retry)
          end
        end
      end

      context 'when job is running' do
        before do
          allow(s3_client).to receive(:get_object).with(bucket: 'barbeque', key: s3_key).and_raise(Aws::S3::Errors::NoSuchKey.new(nil, 'no such key'))
        end

        it 'does nothing' do
          expect(job_retry).to be_running
          expect(job_execution).to be_retried
          executor.poll_retry(job_retry)
          job_retry.reload
          job_execution.reload
          expect(job_retry).to be_running
          expect(job_execution).to be_retried
        end
      end

      context 'when retried job fails' do
        before do
          stopped_info['detail']['containers'][0]['exitCode'] = 1
          allow(s3_client).to receive(:get_object).with(bucket: 'barbeque', key: s3_key).and_return(Aws::S3::Types::GetObjectOutput.new(body: StringIO.new(JSON.dump(stopped_info))))
        end

        it 'sets failed status' do
          expect(job_retry).to be_running
          expect(job_execution).to be_retried
          executor.poll_retry(job_retry)
          job_retry.reload
          job_execution.reload
          expect(job_retry).to be_failed
          expect(job_execution).to be_failed
        end

        context 'when slack_notification is configured' do
          let(:slack_client) { double('Barbeque::SlackClient') }
          let(:slack_notification) { FactoryBot.create(:slack_notification, notify_success: false) }

          before do
            job_execution.job_definition.update!(slack_notification: slack_notification)
            allow(Barbeque::SlackClient).to receive(:new).with(slack_notification.channel).and_return(slack_client)
          end

          it 'sends slack notification' do
            expect(slack_client).to receive(:notify_failure)
            executor.poll_retry(job_retry)
          end
        end

        context 'with retry_config' do
          before do
            FactoryBot.create(:retry_config, job_definition: job_definition)
          end

          it 'performs retry' do
            expect(Barbeque::MessageRetryingService.sqs_client).to receive(:send_message).with(queue_url: a_kind_of(String), message_body: a_kind_of(String), delay_seconds: a_kind_of(Integer))
            expect(job_retry).to be_running
            expect(job_execution).to be_retried
            executor.poll_retry(job_retry)
            job_retry.reload
            job_execution.reload
            expect(job_retry).to be_failed
            expect(job_execution).to be_retried
          end
        end
      end
    end
  end
end
