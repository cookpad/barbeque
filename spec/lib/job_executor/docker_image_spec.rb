require 'job_executor/docker_image'

describe JobExecutor::DockerImage do
  it 'parses docker image name without a tag' do
    image = JobExecutor::DockerImage.new('cookpad')
    expect(image.repository).to eq('cookpad')
    expect(image.tag).to eq('latest')
  end

  it 'parses docker image name with a tag' do
    image = JobExecutor::DockerImage.new('cookpad-ruby:2.2')
    expect(image.repository).to eq('cookpad-ruby')
    expect(image.tag).to eq('2.2')
  end

  it 'parses docker image name with a host' do
    image = JobExecutor::DockerImage.new('docker.io/library/ruby')
    expect(image.repository).to eq('library/ruby')
    expect(image.tag).to eq('latest')
    expect(image.registry).to eq('docker.io')
  end

  describe '#to_s' do
    context 'with docker registry specified' do
      let(:image_name) { 'cookpad-ruby:2.2' }
      let(:docker_registry) { 'docker-registry-001:80' }

      around do |example|
        begin
          orig, ENV['BARBEQUE_DOCKER_REGISTRY'] = ENV['BARBEQUE_DOCKER_REGISTRY'], docker_registry
          example.run
        ensure
          ENV['BARBEQUE_DOCKER_REGISTRY'] = orig
        end
      end

      it 'prepends docker registry' do
        image = JobExecutor::DockerImage.new(image_name)
        expect(image.to_s).to eq("#{docker_registry}/#{image_name}")
      end
    end
  end
end
