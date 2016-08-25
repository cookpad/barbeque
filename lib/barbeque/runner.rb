require 'barbeque/configuration'
require 'barbeque/runner/docker'

module Barbeque
  module Runner
    # @param [DockerImage] docker_image
    def self.create(docker_image:)
      klass = const_get(Barbeque.config.runner, false)
      klass.new(docker_image: docker_image)
    end
  end
end
