Barbeque::Engine.routes.draw do
  root to: 'apps#index'

  resources :apps, except: :index

  resources :job_definitions do
    get :stats
    get :execution_stats
  end

  resources :job_executions, only: :show do
    post :retry

    resources :job_retries, only: :show
  end

  resources :job_queues

  resources :sns_subscriptions

  resources :monitors, only: %i[index]

  scope :v1, module: 'api', as: :v1 do
    resources :apps, only: [], param: :name, constraints: { name: /[\w-]+/ } do
      resource :revision_lock, only: [:create, :destroy]
    end

    resources :job_executions, only: :show, param: :message_id,
      constraints: { message_id: /[a-f\d]{8}-([a-f\d]{4}-){3}[a-f\d]{12}/ } do
      resources :job_retries, only: [:create], path: 'retries'
    end
  end

  scope :v2, module: 'api', as: :v2 do
    resources :job_executions, only: :create, param: :message_id,
      constraints: { message_id: /[a-f\d]{8}-([a-f\d]{4}-){3}[a-f\d]{12}/ }
  end
end
