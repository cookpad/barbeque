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
