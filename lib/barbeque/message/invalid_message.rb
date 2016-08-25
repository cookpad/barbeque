require 'barbeque/message/base'

module Barbeque
  module Message
    class InvalidMessage < Base
      def valid?
        false
      end
    end
  end
end
