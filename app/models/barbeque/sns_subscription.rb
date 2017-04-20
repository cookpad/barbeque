module Barbeque
  class SNSSubscription < ApplicationRecord
    belongs_to :job_queue
    belongs_to :job_definition
  end
end
