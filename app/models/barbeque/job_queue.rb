class Barbeque::JobQueue < Barbeque::ApplicationRecord
  SQS_NAME_PREFIX = ENV['BARBEQUE_SQS_NAME_PREFIX'] || 'Barbeque-'
  SQS_NAME_MAX_LENGTH = 80

  has_many :sns_subscriptions, class_name: 'SNSSubscription', dependent: :destroy

  # SQS queue allows [a-zA-Z0-9_-]+ as queue name. Its maximum length is 80.
  validates :name, presence: true, uniqueness: true, format: /\A[a-zA-Z0-9_-]+\z/,
    length: { maximum: SQS_NAME_MAX_LENGTH - SQS_NAME_PREFIX.length }

  attr_readonly :name

  def sqs_queue_name
    SQS_NAME_PREFIX + name
  end
end
