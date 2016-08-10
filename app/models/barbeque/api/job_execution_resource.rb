class Barbeque::Api::JobExecutionResource < Barbeque::Api::ApplicationResource
  property :message_id

  property :status

  delegate :message_id, :status, to: :model
end
