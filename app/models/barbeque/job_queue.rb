class Barbeque::JobQueue < Barbeque::ApplicationRecord
  SQS_NAME_PREFIX = ENV['BARBEQUE_SQS_NAME_PREFIX'] || 'Barbeque-'
  SQS_NAME_MAX_LENGTH = 80

  has_many :job_executions
  has_many :sns_subscriptions, class_name: 'SNSSubscription', dependent: :destroy

  # SQS queue allows [a-zA-Z0-9_-]+ as queue name. Its maximum length is 80.
  validates :name, presence: true, uniqueness: true, format: /\A[a-zA-Z0-9_-]+\z/,
    length: { maximum: SQS_NAME_MAX_LENGTH - SQS_NAME_PREFIX.length }

  attr_readonly :name

  def sqs_queue_name
    SQS_NAME_PREFIX + name
  end

  # Returns queue URL of given name.
  # Basically, we should use stored queue URL as the documentation[1] suggests.
  # But when the Barbeque's database is temporarily unavailable due to
  # scheduled maintenance, we have to build queue URL without the database. The
  # maintenance mode is enabled by BARBEQUE_DATABASE_MAINTENANCE and
  # AWS_ACCOUNT_ID variable.
  # [1]: http://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html#sqs-general-identifiers
  #
  # @param name [String] queue name in Barbeque
  # @return [String] queue URL of SQS
  def self.queue_url_from_name(name)
    if database_maintenance_mode?
      "https://sqs.#{ENV.fetch('AWS_REGION')}.amazonaws.com/#{ENV.fetch('AWS_ACCOUNT_ID')}/#{SQS_NAME_PREFIX}#{name}"
    else
      select(:queue_url).find_by!(name: name).queue_url
    end
  end

  def self.database_maintenance_mode?
    ENV['BARBEQUE_DATABASE_MAINTENANCE'] == '1' && ENV['AWS_REGION'].present? && ENV['AWS_ACCOUNT_ID'].present?
  end
  private_class_method :database_maintenance_mode?
end
