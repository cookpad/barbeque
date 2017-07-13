require 'barbeque/config'
require 'barbeque/executor/docker'
require 'barbeque/executor/hako'

module Barbeque
  module Executor
    # @param [Barbeque::DockerImage] docker_image
    def self.create(docker_image:)
      klass = const_get(Barbeque.config.executor, false)
      klass.new(Barbeque.config.executor_options.merge(docker_image: docker_image))
    end
  end
end
