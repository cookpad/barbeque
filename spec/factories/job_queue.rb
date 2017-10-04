FactoryGirl.define do
  factory :job_queue, class: Barbeque::JobQueue do
    sequence(:name) { |n| "queue-#{n}" }
    queue_url { "https://sqs.ap-northeast-1.amazonaws.com/123456789012/Barbeque-#{name}" }
    description 'Default queue'
  end
end
