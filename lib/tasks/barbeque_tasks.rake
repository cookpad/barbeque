namespace :barbeque do
  desc 'Start worker to execute jobs'
  task worker: :environment do
    ENV['BARBEQUE_QUEUE'] ||= 'default'

    require 'barbeque/worker'
    Barbeque::Worker.run
  end
end
