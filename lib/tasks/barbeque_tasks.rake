desc 'Start worker to execute jobs'
task job_executor: :environment do
  ENV['BARBEQUE_QUEUE'] ||= 'default'

  require 'job_executor'
  JobExecutor.run
end
