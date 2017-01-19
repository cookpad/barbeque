require 'barbeque/config'

module Barbeque
  module ExceptionHandler
    class << self
      def handle_exception(e)
        handler.handle_exception(e)
      end

      private

      def handler
        @handler ||= const_get(Barbeque.config.exception_handler, false)
      end
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
