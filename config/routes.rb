Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "leaderboard#index"
  resources :players, only: [ :show ]
  get "rules", to: "pages#rules", as: :rules

  get  "gallery",       to: "gallery#show",          as: :gallery
  get  "gallery/login", to: "gallery#login",         as: :gallery_login
  post "gallery/login", to: "gallery#authenticate",  as: :gallery_authenticate

  namespace :admin do
    root "players#index"
    get  "login",  to: "sessions#new"
    post "login",  to: "sessions#create"
    delete "logout", to: "sessions#destroy"
    resources :players
    resources :tours, only: [ :index, :show, :edit, :update ] do
      resources :games, only: [ :edit, :update ]
    end
    get  "pages/:slug/edit", to: "pages#edit",   as: :edit_page
    patch "pages/:slug",     to: "pages#update", as: :page
  end
end
