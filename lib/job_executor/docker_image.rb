module JobExecutor
  class DockerImage
    DEFAULT_TAG = 'latest'

    def initialize(str)
      # See: https://github.com/docker/docker/blob/v1.10.2/image/spec/v1.md
      result = str.match(%r{((?<registry>[^/]+)?/)?(?<repository>[\w./-]+)(:(?<tag>[\w.-]+))?\z})
      @repository = result[:repository]
      @tag        = result[:tag] || DEFAULT_TAG
      @registry   = result[:registry] || ENV['BARBEQUE_DOCKER_REGISTRY']
    end

    attr_reader :registry, :repository
    attr_accessor :tag

    def to_s
      [registry, "#{repository}:#{tag}"].compact.join('/')
    end
  end
end
