require 'barbeque/configuration'

describe Barbeque::Configuration do
  describe '#build_config' do
    let(:yaml) do
      <<-YAML.strip_heredoc
        rails_env:
          runner: Runner
      YAML
    end

    before do
      allow(Rails).to receive(:env).and_return('rails_env')
      allow(File).to receive(:read).
        with(Rails.root.join('config', 'barbeque.yml').to_s).
        and_return(yaml)
    end

    it 'returns Hashie::Mash loaded from config/barbeque.yml' do
      config = Barbeque.build_config
      expect(config.runner).to eq('Runner')
    end

    context 'given erb' do
      let(:yaml) do
        <<-YAML.strip_heredoc
          rails_env:
            runner: <%= 'Foo' + 'Bar' %>
        YAML
      end

      it 'evaluates barbeque.yml as erb' do
        config = Barbeque.build_config
        expect(config.runner).to eq('FooBar')
      end
    end
  end
end
