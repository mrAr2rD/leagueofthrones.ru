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
    get "tides-of-battle", to: "tides_of_battle_sessions#new", as: :tides_of_battle
    get "tides-of-battle/:token", to: "tides_of_battle_sessions#show", as: :tides_of_battle_session
    post "tides-of-battle/:token/:side/draw", to: "tides_of_battle_sessions#draw", as: :tides_of_battle_draw
    post "tides-of-battle/:token/:side/peek", to: "tides_of_battle_sessions#peek", as: :tides_of_battle_peek
    post "tides-of-battle/:token/:side/reroll", to: "tides_of_battle_sessions#reroll", as: :tides_of_battle_reroll
    post "tides-of-battle/:token/reveal", to: "tides_of_battle_sessions#reveal", as: :tides_of_battle_reveal
    resources :players, only: [ :show ]
  end
end
