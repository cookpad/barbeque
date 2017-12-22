FactoryBot.define do
  factory :job_definition, class: Barbeque::JobDefinition do
    sequence(:job) { |n| "AsyncJob#{n}" }
    app
    command %w[bundle exec rake job_executor]
  end
end
