FactoryGirl.define do
  factory :job_retry do
    message_id { SecureRandom.uuid }
    status 1
    finished_at "2016-05-16 13:17:10"
    job_execution
  end
end
