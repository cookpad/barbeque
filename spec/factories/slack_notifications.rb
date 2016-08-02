FactoryGirl.define do
  factory :slack_notification do
    channel '#tech'
    notify_success false
    failure_notification_text '@k0kubun'
  end
end
