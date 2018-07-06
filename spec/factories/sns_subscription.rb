FactoryBot.define do
  factory :sns_subscription, class: Barbeque::SNSSubscription do
    sequence(:topic_arn) { |n| "arn:aws:sns:ap-northeast-1:123456789012/Topic-#{n}" }
    job_queue
    job_definition
  end
end
