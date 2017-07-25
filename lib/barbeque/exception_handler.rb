require 'barbeque/config'

module Barbeque
  module ExceptionHandler
    class << self
      delegate :clear_context, :set_message_context, :handle_exception, to: :handler

      private

      def handler
        @handler ||= const_get(Barbeque.config.exception_handler, false).new
      end
    end

    class RailsLogger
      def initialize
        clear_context
      end

      def clear_context
        @message_id = nil
        @message_type = nil
      end

      # @param [String] message_id
      # @param [String, nil] message_type
      def set_message_context(message_id, message_type)
        @message_id = message_id
        @message_type = message_type
      end

      # @param [Exception] e
      def handle_exception(e)
        Rails.logger.error("#{e.inspect}\nmessage_id: #{@message_id}, message_type: #{@message_type}\n#{e.backtrace.join("\n")}")
      end
    end

    class Raven
      def clear_context
        ::Raven::Context.clear!
      end

      # @param [String] message_id
      # @param [String, nil] message_type
      def set_message_context(message_id, message_type)
        ::Raven.tags_context(message_id: message_id, message_type: message_type)
      end

      # @param [Exception] e
      def handle_exception(e)
        ::Raven.capture_exception(e)
      end
    end
  end
end
