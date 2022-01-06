class Barbeque::JobDefinitionsController < Barbeque::ApplicationController
  def index
    @job_definitions = Barbeque::JobDefinition.all
  end

  def show
    @job_definition = Barbeque::JobDefinition.find(params[:id])
    @job_executions = @job_definition.job_executions.order(id: :desc).page(params[:page])
    @retry_config = @job_definition.retry_config
    @status = params[:status].presence.try(&:to_i)
    if @status
      @job_executions = @job_executions.where(status: @status)
    end
  end

  def new
    @job_definition = Barbeque::JobDefinition.new
    @job_definition.build_slack_notification
    @job_definition.build_retry_config
    if params[:job_definition]
      @job_definition.assign_attributes(new_job_definition_params)
    end
  end

  def edit
    @job_definition = Barbeque::JobDefinition.find(params[:id])
    unless @job_definition.slack_notification
      @job_definition.build_slack_notification
    end
    unless @job_definition.retry_config
      @job_definition.build_retry_config
    end
  end

  def create
    attributes = new_job_definition_params.merge(command: command_array)
    @job_definition = Barbeque::JobDefinition.new(attributes)

    if @job_definition.save
      redirect_to @job_definition, notice: 'Job definition was successfully created.'
    else
      render :new
    end
  end

  def update
    @job_definition = Barbeque::JobDefinition.find(params[:id])
    attributes = params.require(:job_definition).permit(
      :description,
      slack_notification_attributes: slack_notification_params,
      retry_config_attributes: retry_config_params,
    ).merge(command: command_array)
    if @job_definition.update(attributes)
      redirect_to @job_definition, notice: 'Job definition was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @job_definition = Barbeque::JobDefinition.find(params[:id])
    @job_definition.sns_subscriptions.each do |sns_subscription|
      Barbeque::SnsSubscriptionService.new.unsubscribe(sns_subscription)
    end
    @job_definition.destroy
    redirect_to job_definitions_url, notice: 'Job definition was successfully destroyed.'
  end

  def stats
    @job_definition = Barbeque::JobDefinition.find(params[:job_definition_id])
    @days = (params[:days] || 3).to_i
  end

  def execution_stats
    job_definition = Barbeque::JobDefinition.find(params[:job_definition_id])
    days = (params[:days] || 3).to_i
    now = Time.zone.now
    render json: job_definition.execution_stats(days.days.ago(now), now)
  end

  private

  def slack_notification_params
    %i[id channel notify_success notify_failure_only_if_retry_limit_reached failure_notification_text _destroy]
  end

  def retry_config_params
    %i[id retry_limit base_delay max_delay jitter _destroy]
  end

  def command_array
    Shellwords.split(params.require(:job_definition)[:command])
  end

  def new_job_definition_params
    params.require(:job_definition).permit(
      :job,
      :app_id,
      :description,
      slack_notification_attributes: slack_notification_params,
      retry_config_attributes: retry_config_params,
    )
  end
end
