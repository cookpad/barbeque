require 'rails_helper'
require 'barbeque/runner'

describe Barbeque::Runner do
  describe '.create' do
    let(:docker_image) { 'cookpad' }

    before do
      config = Barbeque.build_config(barbeque_yml)
      allow(Barbeque).to receive(:config).and_return(config)
    end

    context 'without runner_options' do
      let(:barbeque_yml) { 'barbeque.yml' }

      it 'initializes a configured runner with docker_image' do
        expect(Barbeque::Runner::Docker).to receive(:new).with(
          docker_image: docker_image,
        )
        Barbeque::Runner.create(docker_image: docker_image)
      end
    end

    context 'with runner_options' do
      let(:barbeque_yml) { 'barbeque.hako.yml' }

      it 'initializes a configured runner with docker_image and configured options' do
        expect(Barbeque::Runner::Hako).to receive(:new).with(
          docker_image: docker_image,
          hako_dir: '/home/k0kubun/hako_repo',
          hako_env: { 'ACCESS_TOKEN' => 'token' },
        )
        Barbeque::Runner.create(docker_image: docker_image)
      end
    end
  end
end
