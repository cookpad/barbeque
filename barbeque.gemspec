$:.push File.expand_path("../lib", __FILE__)
require "barbeque/version"

Gem::Specification.new do |s|
  s.name        = "barbeque"
  s.version     = Barbeque::VERSION
  s.authors     = ["Takashi Kokubun"]
  s.email       = ["takashi-kokubun@cookpad.com"]
  s.homepage    = "https://github.com/cookpad/barbeque"
  s.summary     = "Job queue system to run job with Docker"
  s.description = "Job queue system to run job with Docker"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib,vendor}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.required_ruby_version = '>= 3.0.0'

  s.add_dependency "aws-sdk-cloudwatch"
  s.add_dependency "aws-sdk-ecs"
  s.add_dependency "aws-sdk-s3"
  s.add_dependency "aws-sdk-sns"
  s.add_dependency "aws-sdk-sqs"
  s.add_dependency "hamlit"
  s.add_dependency "jquery-rails"
  s.add_dependency "kaminari", ">= 1.2.1"
  s.add_dependency "rails", "~> 7.0.5"
  s.add_dependency "rinku"
  s.add_dependency "sass-rails"
  s.add_dependency "serverengine"
  s.add_dependency "the_garage"
  s.add_dependency "uglifier"
  s.add_dependency "weak_parameters"

  s.add_development_dependency "autodoc"
  s.add_development_dependency "factory_bot_rails", ">= 5.0.0"
  s.add_development_dependency "listen"
  s.add_development_dependency "mysql2"
  s.add_development_dependency "rspec-rails"
end
