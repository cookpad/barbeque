require 'rails_helper'

describe Barbeque::AppsController do
  routes { Barbeque::Engine.routes }

  describe '#index' do
    let!(:app) { create(:app) }

    it 'shows all apps' do
      get :index
      expect(assigns(:apps)).to eq([app])
    end
  end

  describe '#show' do
    let!(:app) { create(:app) }

    it 'shows a requested app' do
      get :show, params: { id: app.id }
      expect(assigns(:app)).to eq(app)
    end
  end

  describe '#new' do
    it 'assigns a new app' do
      get :new
      expect(assigns(:app)).to be_a_new(Barbeque::App)
    end
  end

  describe '#edit' do
    let!(:app) { create(:app) }

    it 'assigns a requested app' do
      get :edit, params: { id: app.id }
      expect(assigns(:app)).to eq(app)
    end
  end

  describe '#create' do
    let(:attributes) { { name: 'cookpad', docker_image: 'cookpad', description: 'cookpad app' } }

    it 'creates an application' do
      expect {
        post :create, params: { app: attributes }
      }.to change(Barbeque::App, :count).by(1)
    end

    context 'given duplicated name' do
      let(:name) { 'duplicated_name' }
      let(:attributes) { { name: name, docker_image: 'cookpad', description: 'cookpad app' } }

      before do
        create(:app, name: name)
      end

      it 'rejects to create a job_queue' do
        expect {
          post :create, params: { app: attributes }
        }.to_not change(Barbeque::App, :count)
      end
    end
  end

  describe '#update' do
    let(:old_attributes) { { 'docker_image' => 'cookpad-ruby:2.2', 'description' => 'Ruby 2.2' } }
    let(:new_attributes) { { 'docker_image' => 'cookpad-ruby:2.3', 'description' => 'Ruby 2.3' } }
    let!(:app) { create(:app, old_attributes) }

    it 'updates a requested app' do
      expect {
        put :update, params: { id: app.id, app: new_attributes }
      }.to change {
        app.reload.attributes.slice('docker_image', 'description')
      }.from(old_attributes).to(new_attributes)
    end
  end

  describe '#destroy' do
    let!(:app) { create(:app) }

    it 'destroys a requested app' do
      expect {
        delete :destroy, params: { id: app.id }
      }.to change(Barbeque::App, :count).by(-1)
    end
  end
end
