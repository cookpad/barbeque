require 'rails_helper'

describe 'job_executions' do
  let(:env) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json' } }

  describe 'POST /v1/apps/:app_id/revision_lock' do
    let(:old_revision) { 'latest' }
    let(:new_revision) { '798926db1e623cd51245b70b1f1acb40d780ddc1' }
    let(:registry) { 'docker-registry-001:80' }
    let(:docker_app) { create(:app, docker_image: "barbeque:#{old_revision}") }

    around do |example|
      ENV['BARBEQUE_DOCKER_REGISTRY'], original = registry, ENV['BARBEQUE_DOCKER_REGISTRY']
      example.run
      ENV['BARBEQUE_DOCKER_REGISTRY'] = original
    end

    it 'updates a tag of docker_image', :autodoc do
      expect {
        post "/v1/apps/#{docker_app.name}/revision_lock", env: env, params: {
          revision: new_revision,
        }.to_json
      }.to change {
        docker_app.reload.docker_image
      }.from("barbeque:#{old_revision}").to("#{registry}/barbeque:#{new_revision}")
    end

    context 'when BARBEQUE_DOCKER_REGISTRY is not set' do
      let(:registry) { nil }

      it 'leaves a registry part empty' do
        expect {
          post "/v1/apps/#{docker_app.name}/revision_lock", env: env, params: {
            revision: new_revision,
          }.to_json
        }.to change {
          docker_app.reload.docker_image
        }.from("barbeque:#{old_revision}").to("barbeque:#{new_revision}")
      end
    end
  end

  describe 'DELETE /v1/apps/:app_id/revision_lock' do
    let(:old_revision) { '798926db1e623cd51245b70b1f1acb40d780ddc1' }
    let(:new_revision) { 'latest' }
    let(:registry) { 'docker-registry-001:80' }
    let(:docker_app) { create(:app, docker_image: "barbeque:#{old_revision}") }

    around do |example|
      ENV['BARBEQUE_DOCKER_REGISTRY'], original = registry, ENV['BARBEQUE_DOCKER_REGISTRY']
      example.run
      ENV['BARBEQUE_DOCKER_REGISTRY'] = original
    end

    it 'updates a tag of docker_image', :autodoc do
      expect {
        delete "/v1/apps/#{docker_app.name}/revision_lock", env: env
      }.to change {
        docker_app.reload.docker_image
      }.from("barbeque:#{old_revision}").to("#{registry}/barbeque:#{new_revision}")
    end

    context 'when BARBEQUE_DOCKER_REGISTRY is not set' do
      let(:registry) { nil }

      it 'leaves a registry part empty' do
        expect {
          delete "/v1/apps/#{docker_app.name}/revision_lock", env: env
        }.to change {
          docker_app.reload.docker_image
        }.from("barbeque:#{old_revision}").to("barbeque:#{new_revision}")
      end
    end
  end
end
