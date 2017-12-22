FactoryBot.define do
  factory :job_execution, class: Barbeque::JobExecution do
    message_id { SecureRandom.uuid }
    status :success
    job_definition
    job_queue
  end
end
