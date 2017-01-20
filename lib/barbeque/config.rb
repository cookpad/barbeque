require 'erb'
require 'yaml'

module Barbeque
  class Config
    attr_accessor :exception_handler, :runner, :runner_options

    def initialize(options = {})
      options.each do |key, value|
        if respond_to?("#{key}=")
          public_send("#{key}=", value)
        else
          raise KeyError.new("Unexpected option '#{key}' was specified.")
        end
      end
      runner_options.symbolize_keys!
    end
  end

  module ConfigBuilder
    DEFAULT_CONFIG = {
      'exception_handler' => 'RailsLogger',
      'runner'            => 'Docker',
      'runner_options'    => {},
    }

    def config
      @config ||= build_config
    end

    def build_config(config_name = 'barbeque')
      Config.new(DEFAULT_CONFIG.merge(Rails.application.config_for(config_name)))
    end
  end

  extend ConfigBuilder
end
