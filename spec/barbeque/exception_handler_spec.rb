require 'rails_helper'
require 'barbeque/exception_handler'

describe Barbeque::ExceptionHandler do
  describe '.handle_exception' do
    let(:exception) do
      StandardError.new('something went wrong').tap do |e|
        e.set_backtrace(['barbeque.rb:1'])
      end
    end
    let(:handler) { 'RailsLogger' }

    before do
      allow(Barbeque).to receive_message_chain(:config, :exception_handler).and_return(handler)
    end

    it 'handles exception with configured handler' do
      expect_any_instance_of(Barbeque::ExceptionHandler::RailsLogger).to receive(:handle_exception).with(exception)
      Barbeque::ExceptionHandler.handle_exception(exception)
    end
  end
end
