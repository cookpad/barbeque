require 'docker_image'

class Api::RevisionLockResource < Api::ApplicationResource
  property :revision

  def revision
    DockerImage.new(@model.docker_image).tag
  end
end
