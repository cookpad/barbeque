require 'rails_helper'
require 'barbeque/config'

describe Barbeque::ConfigBuilder do
  describe '#build_config' do
    it 'returns Barbeque::Config loaded from config/barbeque.yml' do
      config = Barbeque.build_config
      expect(config.runner).to eq('Docker')
    end

    context 'when it has no config' do
      before do
        stub_const("Barbeque::ConfigBuilder::DEFAULT_CONFIG", { 'runner' => 'Runner' })
      end

      it 'returns default config' do
        config = Barbeque.build_config('barbeque.empty')
        expect(config.runner).to eq('Runner')
      end
    end

    context 'given erb' do
      it 'evaluates barbeque.yml as erb' do
        config = Barbeque.build_config('barbeque.erb')
        expect(config.runner).to eq('FooBar')
      end
    end
  end
end
