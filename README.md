# Barbeque [![Build Status](https://travis-ci.org/cookpad/barbeque.svg?branch=master)](https://travis-ci.org/cookpad/barbeque)

Job queue system to run job with Docker

<img src="https://raw.githubusercontent.com/k0kubun/barbeque/master/doc/images/job_definitions.png" height="280px" />
<img src="https://raw.githubusercontent.com/k0kubun/barbeque/master/doc/images/statistics.png" height="280px" />

## Project Status

Barbeque is under development but already used on production at Cookpad.  
Documentation and open-sourcing plugins are work in progress.

## What's Barbeque?

Barbeque is a job queue system that consists of:

- Web console to manage jobs
- Web API to queue a job
- Worker to execute a job

A job for Barbeque is a command you configured on web console.
A message serialized by JSON and a job name are given to the command when performed.
In Barbeque worker, they are done on Docker container.

## Why Barbeque?

- You can achieve job-level auto scaling using tools like [Amazon ECS](https://aws.amazon.com/ecs/) and [EC2 Auto Scaling group](https://aws.amazon.com/autoscaling/)
  - It requires plugin to run job with ECS, but it's not open-sourced for now
- You don't have to manage infrastructure for each application like Resque or Sidekiq

For details, see [Scalable Job Queue System Built with Docker // Speaker Deck](https://speakerdeck.com/k0kubun/scalable-job-queue-system-built-with-docker).

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'barbeque'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install barbeque
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
