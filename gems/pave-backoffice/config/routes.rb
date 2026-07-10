Pave::Backoffice::Engine.routes.draw do
  get "/sign_in", to: "sessions#new", as: :sign_in
  post "/sign_in", to: "sessions#create", as: :session
  delete "/sign_out", to: "sessions#destroy", as: :sign_out

  scope module: "mfa", path: "mfa", as: "mfa" do
    resource :challenge, only: [ :show, :create ]
    resource :passkeys, only: [ :create ] do
      post :registration_options
      post :authentication_options
      post :authenticate
    end
    resource :totp_enrollment, only: [ :new, :create ]
    resource :recovery_codes, only: [ :show, :create ]
  end

  get "/", to: "platform/dashboard#show", as: :dashboard

  resource :profile, only: [ :edit, :update ], controller: "profiles"
  scope "profile", as: "profile" do
    get "security", to: "profile_security#show"

    scope module: "profile_security", path: "security", as: "security" do
      resource :password, only: :update
      resource :totp_enrollment, only: [ :new, :create, :destroy ]
      resources :passkeys, only: [ :create, :destroy ] do
        collection do
          post :registration_options
        end
      end
      resource :recovery_codes, only: [ :show ] do
        post :regenerate
        post :acknowledge
      end
    end
  end

  resources :users, only: [ :index, :show ], controller: "platform/users" do
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
