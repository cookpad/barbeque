require 'serverengine'
require 'job_executor/worker'

module JobExecutor
  def self.run
    options = {
      worker_type: 'process',
      workers:     (ENV['BARBEQUE_WORKER_NUM'] || 4).to_i,
      daemonize:   ENV['DAEMONIZE_BARBEQUE'] == '1',
      log:         Rails.env.production? ? Rails.root.join("log/job_executor.log").to_s : $stdout,
      log_level:   Rails.env.production? ? :info : :debug,
      pid_path:    Rails.root.join('tmp/pids/job_executor.pid').to_s,
      supervisor:  Rails.env.production?,
    }

    worker = ServerEngine.create(nil, JobExecutor::Worker, options)
    worker.run
  end
end
