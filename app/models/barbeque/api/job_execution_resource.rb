class Barbeque::Api::JobExecutionResource < Barbeque::Api::ApplicationResource
  property :message_id
  property :status
  property :id
  property :html_url, selectable: true
  property :message, selectable: true

  delegate :message_id, :status, :id, to: :model

  def html_url
    if model.id
      Barbeque::Engine.routes.url_helpers.job_execution_url(model, host: ENV['BARBEQUE_HOST'])
    else
      nil
    end
  end

  def message
    log = @model.execution_log
    if log
      log['message']
    end
  end
end
