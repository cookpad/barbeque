require 'barbeque/configuration'

module Barbeque
  module ExceptionHandler
    class << self
      def handle_exception(e)
        case Barbeque.config.exception_handler
        when 'rails_logger'
          rails_logger(e)
        when 'raven'
          Raven.capture_exception(e)
        else
          Rails.logger.fatal("Unexpected exception handler: #{Barbeque.config.exception_handler}")
          rails_logger(e)
        end
      end

      private

      def rails_logger(e)
        Rails.logger.error("#{e.inspect}\n#{e.backtrace.join("\n")}")
      end
    end
  end
end
