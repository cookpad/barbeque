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

  s.add_dependency "rails", "~> 5.0.0"

  s.add_development_dependency "sqlite3"
end
