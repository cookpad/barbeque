begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rdoc/task'

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Barbeque'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.md')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'bundler/gem_tasks'
require File.expand_path('../spec/dummy/config/application', __FILE__)

namespace :plotly do
  desc 'Update plotly.js to specified version'
  task :update, [:version] do |t, args|
    sh "curl -sfL https://github.com/plotly/plotly.js/archive/v#{args[:version]}.tar.gz | tar zxf - plotly.js-#{args[:version]}/dist/plotly-basic.js -O > vendor/assets/javascripts/plotly-basic.js"
  end
end

Rails.application.load_tasks
