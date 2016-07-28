require 'job_executor/docker_image'

class Api::RevisionLockResource < Api::ApplicationResource
  property :revision

  def revision
    JobExecutor::DockerImage.new(@model.docker_image).tag
  end
end
