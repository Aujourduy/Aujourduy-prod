Rails.application.routes.draw do
  get "event_occurrences/edit"
  get "event_occurrences/update"
  # Route générique pour toutes les vues dans app/views/test/ 
  get "/test/:page", to: "test#show"
  # Page index qui liste toutes les vues du dossier test
  get "/test", to: "test#index"
  
  # Route pour les erreurs Avo personnalisées
  get "/avo_error", to: "avo_errors#show", as: :avo_error

  # Protéger Avo avec l'authentification admin (ou tout user en dev)
  authenticate :user, lambda { |u| Rails.env.development? || u.admin? } do
    mount_avo
  end
  
  # Practices avec CRUD complet
  resources :practices
  
  # EventOccurrences (edit/update/destroy pour modifier une occurrence spécifique)
  resources :event_occurrences, only: [:show, :edit, :update, :destroy]
  
  # Events avec actions de récurrence
  resources :events do
    member do
      get :duplicate
    end
    
    collection do
      post :preview_recurrence
    end
  end
  
  resources :venues do
    collection do
      post :geocode
    end
  end
  
  resources :teachers do
    member do
      patch :upload_photo
    end
  end
  
  # === Routes principales ===
  get "home/index"
  get "home/infos"
  get "welcome/index"
  get "/dashboard", to: "dashboard#index", as: :dashboard
  
  # === PWA Routes ===
  get "/manifest.json", to: "pwa#manifest", defaults: { format: :json }, as: :pwa_manifest
  get "/service-worker.js", to: "pwa#service_worker", defaults: { format: :js }
  
  # === NOUVELLES ROUTES : Profil et Favoris ===
  
  # Page profil (configuration des favoris)
  get "/profile", to: "users#show", as: :profile
  patch "/profile", to: "users#update"
  
  # Page "Pour moi" (événements favoris)
  get "/my_events", to: "favorites#index", as: :my_events
  
  # Toggle union/intersection
  patch "/toggle_filter_mode", to: "users#toggle_filter_mode"
  
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  
  # Google OAuth callbacks 
  devise_for :users, controllers: {
    registrations: "users/registrations",
    omniauth_callbacks: "users/omniauth_callbacks"
  }
  
  # Upload avatar route
  post "upload_avatar", to: "users#upload_avatar"
  
  # Phone verification (OTP)
  resource :phone_verification, only: [:new, :create] do
    post :verify, on: :collection
  end
  
  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  
  # Defines the root path route ("/")
  root to: "home#index"
end
