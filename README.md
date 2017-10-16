# Barbeque [![Build Status](https://travis-ci.org/cookpad/barbeque.svg?branch=master)](https://travis-ci.org/cookpad/barbeque)

Job queue system to run job with Docker

<img src="https://raw.githubusercontent.com/cookpad/barbeque/master/doc/images/job_definitions.png" height="280px" />
<img src="https://raw.githubusercontent.com/cookpad/barbeque/master/doc/images/statistics.png" height="280px" />

## Project Status

Barbeque is used on production at Cookpad.

## What's Barbeque?

Barbeque is a job queue system that consists of:

- Web console to manage jobs
- Web API to queue a job
- Worker to execute a job

A job for Barbeque is a command you configured on web console.
A message serialized by JSON and a job name are given to the command when performed.
In Barbeque worker, they are done on Docker container.

## Why Barbeque?

- You can achieve job-level auto scaling using tools like [Amazon ECS](https://aws.amazon.com/ecs/) [EC2 Auto Scaling group](https://aws.amazon.com/autoscaling/)
  - For Amazon ECS, Barbeque has Hako executor
- You don't have to manage infrastructure for each application like Resque or Sidekiq

For details, see [Scalable Job Queue System Built with Docker // Speaker Deck](https://speakerdeck.com/k0kubun/scalable-job-queue-system-built-with-docker).

## Deployment

### Web API & console

Install barbeque.gem to an empty Rails app and mount `Barbeque::Engine`.
And deploy it as you like.

You also need to prepare MySQL, Amazon SQS and Amazon S3.

### Worker

```bash
$ rake barbeque:worker BARBEQUE_QUEUE=default
```

The rake task launches four worker processes.

- Two runners
  - receives message from SQS queue, starts job execution and stores its identifier to the database
- One execution poller
  - gets execution status and reflect it to the database
- One retry poller
  - gets retried execution status and reflect it to the database

## Usage

Web API documentation is available at [doc/toc.md](./doc/toc.md).

### Ruby

[barbeque\_client.gem](https://github.com/cookpad/barbeque_client) has API client and ActiveJob integration.

## Executor
Barbeque executor can be customized in config/barbeque.yml. Executor is responsible for starting executions and getting status of executions.

Barbeque has currently two executors.

### Docker (default)
Barbeque::Executor::Docker starts execution by `docker run --detach` and gets status by `docker inspect`.

### Hako
Barbeque::Executor::Hako starts execution by `hako oneshot --no-wait` and gets status from S3 task notification.

#### Requirement
You must configure CloudWatch Events for putting S3 task notification.
See Hako's documentation for detail.
https://github.com/eagletmt/hako/blob/master/docs/ecs-task-notification.md

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
