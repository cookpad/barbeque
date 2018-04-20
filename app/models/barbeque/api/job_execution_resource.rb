class Barbeque::Api::JobExecutionResource < Barbeque::Api::ApplicationResource
  property :message_id
  property :status
  property :id
  property :html_url, selectable: true
  property :message, selectable: true

  delegate :message_id, :status, :id, to: :model

  def initialize(model, url_options)
    super(model)
    @url_options = url_options
  end

  def html_url
    if model.id
      Barbeque::Engine.routes.url_helpers.job_execution_url(model, @url_options)
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
