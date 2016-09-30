require 'barbeque/configuration'

module Barbeque
  module ExceptionHandler
    def self.handle_exception(e)
      handler = const_get(Barbeque.config.exception_handler, false)
      handler.handle_exception(e)
    end

    module RailsLogger
      def self.handle_exception(e)
        Rails.logger.error("#{e.inspect}\n#{e.backtrace.join("\n")}")
      end
    end

    module Raven
      def self.handle_exception(e)
        ::Raven.capture_exception(e)
      end
    end
  end
end
