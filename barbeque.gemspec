$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "barbeque/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "barbeque"
  s.version     = Barbeque::VERSION
  s.authors     = ["Takashi Kokubun"]
  s.email       = ["takashi-kokubun@cookpad.com"]
  s.homepage    = "https://github.com/cookpad/barbeque"
  s.summary     = "Job queue interface to run job with Docker"
  s.description = "Job queue interface to run job with Docker"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "aws-sdk"
  s.add_dependency "hamlit"
  s.add_dependency "kaminari"
  s.add_dependency "rails", "~> 5.0.0"
  s.add_dependency "the_garage"
  s.add_dependency "weak_parameters"

  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "listen"
  s.add_development_dependency "mysql2"
  s.add_development_dependency "rspec-rails"
end
