module Barbeque
  class SNSSubscription < ApplicationRecord
    belongs_to :job_queue
    belongs_to :job_definition

    validates :topic_arn,
      uniqueness: { scope: :job_queue, message: 'should be set with only one queue' },
      presence: true
    validates :job_queue, presence: true
    validates :job_definition, presence: true

    after_update :update_queue_policy!

    private
    def update_queue_policy!
      job_queue.update_policy!
    end
  end
end
