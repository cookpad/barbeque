require 'docker_image'

class Barbeque::Api::RevisionLockResource < Barbeque::Api::ApplicationResource
  property :revision

  def revision
    DockerImage.new(@model.docker_image).tag
  end
end
