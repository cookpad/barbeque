require 'erb'
require 'yaml'

module Barbeque
  module Configuration
    def config
      @config ||= build_config
    end

    def build_config
      filename = Rails.root.join('config', 'barbeque.yml').to_s
      hash = YAML.load(ERB.new(File.read(filename)).result)
      Hashie::Mash.new(hash[Rails.env])
    end
  end

  extend Configuration
end
