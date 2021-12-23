## v2.8.0 (2021-12-23)
### New features
- Pass `BARBEQUE_SENT_TIMESTAMP` variable to invoked jobs
  - The value is epoch time in milliseconds when the message is sent to the queue. See also: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_ReceiveMessage.html

## v2.7.5 (2020-05-29)
### Bug fixes
- Use kaminari helper to generate links safely

## v2.7.4 (2020-04-08)
### Bug fixes
- Delete the same message multiple times when DeleteMessage results in partial deletion of copies

## v2.7.3 (2020-01-08)
### Bug fixes
- Accept retry configuration on create

## v2.7.2 (2019-11-05)
### Bug fixes
- Wrap JSON message in pre tag for large message

### Changes
- Change job name to case-sensitive

## v2.7.1 (2019-09-13)
### Bug fixes
- Do not count pending retried job executions when checking `maximum_concurrent_executions`

## v2.7.0 (2019-03-18)
### New features
- Add "Notify failure event to Slack only if retry limit reached" option

### Changes
- Change the default value of "Base delay" option from 0.3 seconds to 15 seconds

## v2.6.0 (2019-02-25)
### New features
- Add server-side retry feature

### Changes
- Stop deleting job executions when job definition is deleted
  - Job executions tend to have large number of records, so deleting them is impossible.
- Return 503 in maintenance mode when mysql2 error occurs
- Use `BARBEQUE_HOST` environment variable to generate `html_url` field in API response

## v2.5.0 (2018-08-24)
### New features
- Add selectable `message` field to `GET /v1/job_executions/:message_id` response
- Add `BARBEQUE_VERIFY_ENQUEUED_JOBS` flag to API server which enables the feature that verifies the enqueued job by accessing MySQL
- Add `delay_seconds` parameter to support SQS's delay_seconds
  - This also supports ActiveJob's enqueue_at method.

### Bug fixes
- Show all SNS topics in /sns_subscriptions/new

## v2.4.0 (2018-04-13)
### Changes
- Update Rails to 5.2

## v2.3.0 (2018-04-12)
### Changes
- Add index to barbeque_job_executions.created_at
  - Be careful when you have large number of records in barbeque_job_executions table.

## v2.2.0 (2018-03-07)
### Changes
- Limit concurrent executions per job queue
  - `maximum_concurrent_executions` was applied to all job executions regardless of job queues.
  - Now `maximum_concurrent_executions` is applied to each job queue.
- Poll job executions and job retries only of the specified queue
  - All execution pollers ware polling all job execution/retry statuses.
  - Now execution pollers poll execution/retry statuses of their own job queue.

## v2.1.0 (2017-12-22)
### Improvements
- Support Hako definitions written in Jsonnet
  - Jsonnet format is supported since Hako v2.0.0
- Rename yaml_dir to definition_dir in config/barbeque.yml
  - yaml_dir is still supported with warnings for now

## v2.0.1 (2017-10-04)
### Improvements
- Build queue_url without database when maintenance mode is enabled
  - See https://github.com/cookpad/barbeque/pull/58 for detail

## v2.0.0 (2017-09-19)
### Incompatibilities
- Job execution URL was changed from `/job_executions/:id` to `/job_executions/:message_id`
  - Barbeque v1.0 links are redirected to v2.0 links
  - Job retry URL `/job_executions/:id/job_retries/:id` is also redirected to `/job_executions/:message_id/job_retries/:id`

## v1.4.1 (2017-09-05)
### Bug fixes
- Do not create execution record when sqs:DeleteMessage returns error

## v1.4.0 (2017-08-31)
### Improvements
- Update aws-sdk to v3
  - Use modularized aws-sdk gems

## v1.3.1 (2017-08-31)
### Improvements
- Filter job executions by status

## v1.3.0 (2017-08-21)
### New features
- Show SQS metrics in job queue page

### Improvements
- Update plotly.js to v1.29.3

### Bug fixes
- Do not truncate hover labels in /monitors chart
- Fix Slack notification field in job definition form

## v1.2.2 (2017-08-04)
### Improvements
- Extract S3 client for hako tasks

## v1.2.1 (2017-08-03)
### Bug fixes
- Do not create job_execution record when S3 returns error
- Ignore S3 errors when starting an execution

### Improvements
- Set descriptive title element
- Add breadcrumbs to all pages

## v1.2.0 (2017-07-26)
### Changes
- Update Rails to 5.1

## v1.1.0 (2017-07-25)
### Changes
- Add message context to exception handler
  - Now exception handler is able to track which message is being processed when an exception is raised
### Bug fixes
- Set status to running after creating related records

## v1.0.0 (2017-07-24)
- Introduce Executor as a replacement of Runner
  - `runner` and `runner_options` is renamed to `executor` and `executor_options` respectively
  - Now `rake barbeque:worker` launches three types of process
    - Runner: receives message from SQS queue, starts job execution and stores its identifier to the database
      - In Executor::Docker, the identifier is container id
      - In Executor::Hako, the identifier is ECS cluster and task ARN
    - ExecutionPoller: polls execution status and reflect it to the database
      - In Executor::Docker, uses `docker inspect` command
      - In Executor::Docker, uses S3 task notification JSON
    - RetryPoller: polls retry status and reflect it to the database
      - Same with ExecutionPoller
  - Add `maximum_concurrent_executions` configuration to config/barbeque.yml
    - It controls the number of concurrent job executions
    - The limit is disabled by default
- Drop support for legacy S3 log format
  - Run [migration script](tools/s3-log-migrator.rb) before upgrading to v1.0.0
- Add `sqs_receive_message_wait_time` configuration to config/barbeque.yml
  - This option controls ReceiveMessageWaitTimeSeconds attribute of SQS queue
  - The default value is changed from 20s to 10s

## v0.7.0 (2017-07-12)
- Change S3 log format [#29](https://github.com/cookpad/barbeque/pull/29)
  - The legacy format saves `{message: message.body.to_json, stdout: stdout, stderr: stderr}.to_json` to `#{app}/#{job}/#{message_id}`
  - The new format saves message body to `#{app}/#{job}/#{message_id}/message.json`, stdout to `#{app}/#{job}/#{message_id}/stdout.txt`, and stderr to `#{app}/#{job}/#{message_id}/stderr.txt`
  - The legacy format is still supported in v0.7.0, but will be removed in v1.0.0
    - Migration script is available: [tools/s3-log-migrator.rb](tools/s3-log-migrator.rb)

## v0.6.3 (2017-07-10)
- Add "running" status [#28](https://github.com/cookpad/barbeque/pull/28)

## v0.6.2 (2017-06-06)
- Kill N+1 query [#27](https://github.com/cookpad/barbeque/pull/27)

## v0.6.1 (2017-06-06)
- Show application names for each job definition in SNS subscriptions [#26](https://github.com/cookpad/barbeque/pull/26)

## v0.6.0 (2017-06-05)
- Support JSON-formatted string as Notification massages [#25](https://github.com/cookpad/barbeque/pull/25)

## v0.5.2 (2017-05-23)
- Destroy SNS subscriptions before destroying job definition [#24](https://github.com/cookpad/barbeque/pull/24)

## v0.5.1 (2017-05-01)
- Log message body in error status for retry [#23](https://github.com/cookpad/barbeque/pull/23)

## v0.5.0 (2017-05-01)
- Add error status to job_execution [#22](https://github.com/cookpad/barbeque/pull/22)

## v0.4.1 (2017-04-28)
- Add error handling for AWS SNS API calls [#21](https://github.com/cookpad/barbeque/pull/21)

## v0.4.0 (2017-04-27)
- Support fan-out executions using AWS SNS notifications [#20](https://github.com/cookpad/barbeque/pull/20)

## v0.3.0 (2017-04-17)
- Fix job_retry order in job_execution page [#16](https://github.com/cookpad/barbeque/pull/16)
- Fix Back path to each job definition page [#17](https://github.com/cookpad/barbeque/pull/17)
- Fix "active" class in sidebar [#18](https://github.com/cookpad/barbeque/pull/18)
- Add new page to show recently processed jobs [#19](https://github.com/cookpad/barbeque/pull/19)

## v0.2.4 (2017-04-05)
- Autolink URLs in job_retry outputs [#15](https://github.com/cookpad/barbeque/pull/15)

## v0.2.3 (2017-03-24)
- Make operation to deduplicate messages atomic [#14](https://github.com/cookpad/barbeque/pull/14)

## v0.2.2 (2017-03-16)
- Add execution id and html_url to status API response [#13](https://github.com/cookpad/barbeque/pull/13)

## v0.2.1
- Fix bug in execution statistics [#12](https://github.com/cookpad/barbeque/pull/12)

## v0.2.0
- Add Hako runner [#11](https://github.com/cookpad/barbeque/pull/11)

## v0.1.0
- Handle S3 error on web console [#10](https://github.com/cookpad/barbeque/pull/10)

## v0.0.18
- Reuse AWS credentials assumed from Role [#9](https://github.com/cookpad/barbeque/pull/9)

## v0.0.17
- Move statistics button to upper right on job definition page
- Link app from job definitions index

## v0.0.16
- Autolink stdout and stderr [#8](https://github.com/cookpad/barbeque/pull/8)

## v0.0.15
- Report exception raised in SQS message parser

## v0.0.14
- Allow logging worker exception by Raven [#7](https://github.com/cookpad/barbeque/pull/7)

## v0.0.13
- Allow switching log output by `BARBEQUE_LOG_TO_STDOUT` [#6](https://github.com/cookpad/barbeque/pull/4)

## v0.0.12
- Destroy job definitions after their app destruction [#4](https://github.com/cookpad/barbeque/pull/4)
