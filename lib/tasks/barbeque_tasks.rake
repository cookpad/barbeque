namespace :barbeque do
  desc 'Start worker to execute jobs'
  task worker: :environment do
    ENV['BARBEQUE_QUEUE'] ||= 'default'
    require 'barbeque/worker'

    Barbeque::Worker.run(
      workers:    (ENV['BARBEQUE_WORKER_NUM'] || 4).to_i,
      daemonize:  ENV['DAEMONIZE_BARBEQUE'] == '1',
      log:        ENV['BARBEQUE_LOG_TO_STDOUT'] == '1' ? $stdout : Rails.root.join('log/barbeque_worker.log').to_s,
      log_level:  Rails.env.production? ? :info : :debug,
      pid_path:   Rails.root.join('tmp/pids/barbeque_worker.pid').to_s,
      supervisor: Rails.env.production?,
    )
  end
end
