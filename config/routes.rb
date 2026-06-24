Rails.application.routes.draw do
  # Health checks — liveness (lightweight) and readiness (deep dependency check)
  get "up" => "health#show", as: :rails_health_check
  get "up/ready" => "health#ready", as: :health_ready

  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions",
    omniauth_callbacks: "users/omniauth_callbacks"
  }
  scope :users, as: :user do
    resource :social_registration, only: [ :new, :create ], module: :users

    namespace :mfa, module: "users/mfa" do
      resource :challenge, only: [ :show, :create ]
      resource :passkeys, only: [ :create ] do
        post :registration_options
        post :authentication_options
        post :authenticate
      end
      resource :totp_enrollment, only: [ :new, :create ]
      resource :recovery_codes, only: [ :show, :create ]
    end
  end
  get "privacy-policy", to: "legal#privacy_policy", as: :privacy_policy
  get "terms-of-service", to: "legal#terms_of_service", as: :terms_of_service

  if Rails.env.development?
    Pave.products.each do |product|
      next unless product.dev_subdomain
      constraints(Pave::DevSubdomainConstraint.new(product)) do
        get "/", to: "landing#index"
      end
    end
    root "pave#index"
  else
    root "landing#index"
  end

  Pave.products.draw_routes(self)

  resource :profile, only: [ :edit, :update ], controller: "profiles" do
    post :request_data_export
    post :request_deletion
    delete :cancel_deletion_request
    resource :picture, only: [ :show, :destroy ], controller: "profiles/pictures"
  end
  scope "profile", module: "profiles", as: "profile" do
    get "security", to: "security#show"

    scope module: "security", path: "security", as: "security" do
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
  resource :preferences, only: [ :edit, :update ], controller: "preferences"
  resources :push_subscriptions, only: [ :create ], path: "push-subscriptions"
  resource :push_subscription, only: [ :destroy ], path: "push-subscription"
  resource :push_notification_preference, only: [ :update ], path: "push-notification-preference"

  scope module: "spaces" do
    resources :users, path: "team" do
      resource :picture, only: [ :show ], controller: "user_pictures"
    end
  end

  mount Pave::Backoffice::Engine, at: "/admin", as: :pave_backoffice

  get "/backoffice", to: redirect("/admin")
end
