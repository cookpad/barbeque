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
    sh "curl -sSfL https://github.com/plotly/plotly.js/archive/v#{args[:version]}.tar.gz | tar zxf - plotly.js-#{args[:version]}/dist/plotly-basic.js -O > vendor/assets/javascripts/plotly-basic.js"
  end
end

namespace :bootstrap do
  desc 'Update Bootstrap to specified version'
  task :update, [:version] do |t, args|
    version = args.fetch(:version)
    zipfile = "bootstrap-v#{version}.zip"
    sh "curl -sSfL -o #{zipfile} https://github.com/twbs/bootstrap/releases/download/v#{version}/bootstrap-#{version}-dist.zip"
    sh "bsdtar xf #{zipfile} --strip-components 2 -C vendor/assets/stylesheets bootstrap-#{version}-dist/css/bootstrap.css"
    sh "bsdtar xf #{zipfile} --strip-components 2 -C vendor/assets/javascripts bootstrap-#{version}-dist/js/bootstrap.js"
  end
end

namespace :adminlte do
  desc 'Update AdminLTE to specified version'
  task :update, [:version] do |t, args|
    version = args.fetch(:version)
    tarball = "adminlte-v#{version}.tar.gz"
    sh "curl -sSfL -o #{tarball} https://github.com/ColorlibHQ/AdminLTE/archive/refs/tags/v#{version}.tar.gz"
    sh "tar zxf #{tarball} --strip-components 3 -C vendor/assets/stylesheets AdminLTE-#{version}/dist/css/AdminLTE.css AdminLTE-#{version}/dist/css/skins/skin-blue.css"
    sh "tar zxf #{tarball} --strip-components 3 -C vendor/assets/javascripts AdminLTE-#{version}/dist/js/adminlte.js"
  end
end

Rails.application.load_tasks
