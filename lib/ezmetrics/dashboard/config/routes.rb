Dashboard::Ezmetrics.routes.draw do
  resources :metrics, only: :index
  match "/metrics/aggregate" => "metrics#aggregate", via: [:options, :get]
  match "/" => "metrics#index", via: :get
end
