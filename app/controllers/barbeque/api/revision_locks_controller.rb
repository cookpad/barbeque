class Barbeque::Api::RevisionLocksController < Barbeque::Api::ApplicationController
  include Garage::RestfulActions

  validates :create do
    string :revision, required: true, description: 'Docker image revision to lock'
  end

  private

  def require_resources
    protect_resource_as Barbeque::Api::RevisionLockResource
  end

  def require_resource
    @resource = App.find_by!(name: params[:app_name])
  end

  def create_resource
    app = App.find_by!(name: params[:app_name])
    image = Barbeque::DockerImage.new(app.docker_image)
    image.tag = params[:revision]
    app.update!(docker_image: image.to_s)

    Barbeque::Api::RevisionLockResource.new(app)
  end

  def destroy_resource
    image = Barbeque::DockerImage.new(@resource.docker_image)
    image.tag = 'latest'
    @resource.update!(docker_image: image.to_s)

    Barbeque::Api::RevisionLockResource.new(@resource)
  end
end
