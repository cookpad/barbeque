require 'rails_helper'
require 'barbeque/config'

describe Barbeque::Config do
  describe '#executor_options' do
    it 'returns Hash whose keys are symbolized without symbolizing values' do
      options = { 'foo' => { 'bar' => 'baz' } }
      expect(Barbeque::Config.new(executor_options: options).executor_options).
        to eq({ foo: { 'bar' => 'baz' } })
    end
  end
end
