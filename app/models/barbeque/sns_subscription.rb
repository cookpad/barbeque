module Barbeque
  class SNSSubscription < ApplicationRecord
    belongs_to :job_queue
    belongs_to :job_definition
    has_one :app, through: :job_definition

    validates :topic_arn,
      uniqueness: { scope: :job_queue, message: 'should be set with only one queue' },
      presence: true

    def region
      /\Aarn:aws:sns:([a-z0-9-]+):/.match(topic_arn)[1]
    end
  end
end
