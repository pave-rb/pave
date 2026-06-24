Pave::Backoffice::Engine.routes.draw do
  get "/sign_in", to: "sessions#new", as: :sign_in
  post "/sign_in", to: "sessions#create", as: :session
  delete "/sign_out", to: "sessions#destroy", as: :sign_out

  get "/", to: "platform/dashboard#show", as: :dashboard

  resources :users, only: [:index, :show], controller: "platform/users" do
    member do
      post :grant_super_admin
      post :revoke_super_admin
    end
  end

  get "/audit", to: "platform/audit_events#index", as: :audit
  get "/audit/:id", to: "platform/audit_events#show", as: :audit_event
  get "/settings", to: "platform/settings#index", as: :settings
  patch "/settings", to: "platform/settings#update"

  Pave::Backoffice::RouteDrawer.draw(self)
end
