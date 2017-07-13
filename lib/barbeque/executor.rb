require 'barbeque/config'
require 'barbeque/executor/docker'
require 'barbeque/executor/hako'

module Barbeque
  module Executor
    def self.create
      klass = const_get(Barbeque.config.executor, false)
      klass.new(Barbeque.config.executor_options)
    end
  end
end
