module Barbeque
  module MessageHandler
    class DuplicatedExecution < StandardError; end
  end
end

require 'barbeque/message_handler/job_execution'
require 'barbeque/message_handler/job_retry'
