require 'erb'
require 'yaml'
require 'hashie'

module Barbeque
  module Configuration
    DEFAULT_CONFIG = {
      'exception_handler' => 'rails_logger',
      'runner'            => 'Docker',
    }

    def config
      @config ||= build_config
    end

    def build_config
      filename = Rails.root.join('config', 'barbeque.yml').to_s
      hash = YAML.load(ERB.new(File.read(filename)).result)
      Hashie::Mash.new(DEFAULT_CONFIG.merge(hash[Rails.env]))
    end
  end

  extend Configuration
end
