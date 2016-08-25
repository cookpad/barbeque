class Barbeque::Api::RevisionLockResource < Barbeque::Api::ApplicationResource
  property :revision

  def revision
    Barbeque::DockerImage.new(@model.docker_image).tag
  end
end
