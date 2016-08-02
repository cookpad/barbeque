FactoryGirl.define do
  factory :job_definition do
    sequence(:job) { |n| "AsyncJob#{n}" }
    app
    command %w[bundle exec rake job_executor]
  end
end
