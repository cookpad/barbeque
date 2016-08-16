source 'https://rubygems.org'

# Declare your gem's dependencies in barbeque.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

group :development, :test do
  gem 'pry-byebug'
end

# Following gems don't work if they're required on spec_helper.
# It should be loaded on `Bundler.require` or `before_configuration`,
# and I don't want to to load them on `before_configuration` for test environment.
group :test do
  gem "rails-controller-testing"
end
