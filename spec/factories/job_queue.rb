FactoryGirl.define do
  factory :job_queue, class: Barbeque::JobQueue do
    sequence(:name) { |n| "queue-#{n}" }
    sequence(:queue_url) { |n| "https://sqs.ap-northeast-1.amazonaws.com/123456789012/Barbeque-#{n}" }
    description 'Default queue'
  end
end
