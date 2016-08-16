class Barbeque::JobDefinitionsController < Barbeque::ApplicationController
  def index
    @job_definitions = JobDefinition.all
  end

  def show
    @job_definition = JobDefinition.find(params[:id])
    @job_executions = @job_definition.job_executions.order(id: :desc).page(params[:page])
  end

  def new
    @job_definition = JobDefinition.new
    @job_definition.build_slack_notification
    if params[:job_definition]
      @job_definition.assign_attributes(new_job_definition_params)
    end
  end

  def edit
    @job_definition = JobDefinition.find(params[:id])
    if @job_definition.slack_notification.nil?
      @job_definition.build_slack_notification
    end
  end

  def create
    attributes = new_job_definition_params.merge(command: command_array)
    @job_definition = JobDefinition.new(attributes)

    if @job_definition.save
      redirect_to @job_definition, notice: 'Job definition was successfully created.'
    else
      render :new
    end
  end

  def update
    @job_definition = JobDefinition.find(params[:id])
    attributes = params.require(:job_definition).permit(
      :description,
      slack_notification_attributes: slack_notification_params,
    ).merge(command: command_array)
    if @job_definition.update(attributes)
      redirect_to @job_definition, notice: 'Job definition was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @job_definition = JobDefinition.find(params[:id])
    @job_definition.destroy
    redirect_to job_definitions_url, notice: 'Job definition was successfully destroyed.'
  end

  private

  def slack_notification_params
    %i[id channel notify_success failure_notification_text _destroy]
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
    )
  end
end
