Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Корень — выбор города (или редирект на единственный/дефолтный).
  root "cities#index"

  # Галерея общая для всех городов.
  get  "gallery",       to: "gallery#show",          as: :gallery
  get  "gallery/login", to: "gallery#login",         as: :gallery_login
  post "gallery/login", to: "gallery#authenticate",  as: :gallery_authenticate

  namespace :admin do
    root "players#index"
    get  "login",  to: "sessions#new"
    post "login",  to: "sessions#create"
    delete "logout", to: "sessions#destroy"
    resources :cities, except: [ :show ]
    resources :admin_users, except: [ :show ]
    resources :players
    get "statistics", to: "statistics#show", as: :statistics
    post "statistics/achievements/publish",
         to: "achievement_publications#create",
         as: :statistics_achievements_publish
    patch "statistics/achievements/refresh",
          to: "achievement_publications#update",
          as: :statistics_achievements_refresh
    delete "statistics/achievements/unpublish",
           to: "achievement_publications#destroy",
           as: :statistics_achievements_unpublish
    resources :tours, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
      resources :games, only: [ :edit, :update ]
    end
    resources :pages, only: [ :index, :new, :create, :edit, :update ]
  end

  # Публичная часть скоупится городом: /:city, /:city/players/:id, /:city/rules.
  # Должна идти ПОСЛЕ admin/gallery/health, иначе :city_id перехватит их.
  scope "/:city_id", as: :city do
    get "/",     to: "leaderboard#index", as: :leaderboard
    get "rules", to: "pages#rules",       as: :rules
    resources :players, only: [ :show ]
  end
end
