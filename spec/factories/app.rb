FactoryBot.define do
  factory :app, class: Barbeque::App do
    sequence(:name) { |n| "app-#{n}" }
    sequence(:docker_image) { |n| "app-#{n}:latest" }
    description 'Docker application'
  end
end
