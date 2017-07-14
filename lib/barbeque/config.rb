require 'erb'
require 'yaml'

module Barbeque
  class Config
    attr_accessor :exception_handler, :executor, :executor_options, :sqs_receive_message_wait_time, :maximum_concurrent_executions

    def initialize(options = {})
      options.each do |key, value|
        if respond_to?("#{key}=")
          public_send("#{key}=", value)
        else
          raise KeyError.new("Unexpected option '#{key}' was specified.")
        end
      end
      executor_options.symbolize_keys!
    end
  end

  module ConfigBuilder
    DEFAULT_CONFIG = {
      'exception_handler' => 'RailsLogger',
      'executor' => 'Docker',
      'executor_options' => {},
      # http://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_CreateQueue.html#API_CreateQueue_RequestParameters
      'sqs_receive_message_wait_time' => 10,
      # nil means unlimited
      'maximum_concurrent_executions' => nil,
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
