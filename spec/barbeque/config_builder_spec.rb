require 'rails_helper'
require 'barbeque/config'

describe Barbeque::ConfigBuilder do
  describe '#build_config' do
    it 'returns Barbeque::Config loaded from config/barbeque.yml' do
      config = Barbeque.build_config
      expect(config.executor).to eq('Docker')
    end

    context 'when it has no config' do
      it 'returns default config' do
        config = Barbeque.build_config('barbeque.empty')
        expect(config.executor_options).to eq({})
      end
    end

    context 'given erb' do
      it 'evaluates barbeque.yml as erb' do
        config = Barbeque.build_config('barbeque.erb')
        expect(config.executor).to eq('FooBar')
      end
    end
  end
end
