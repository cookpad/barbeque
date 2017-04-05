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
