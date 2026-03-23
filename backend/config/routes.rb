Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }

  resources :organizations, only: [:index, :show, :create] do
    resources :memberships, only: [:create], module: :organizations
  end

  # Authenticated root → dashboard; unauthenticated → login
  authenticated :user do
    root to: "organizations#index", as: :authenticated_root
  end
  root to: redirect("/users/sign_in")

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
