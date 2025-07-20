Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
  get 'confirm_registration', to: 'registrations#confirm'
  resource :registration, only: [:new,:create]
  resource :session
  resources :passwords, param: :token
  resources :posts,  param: :slug, only: [:edit, :show]
  resources :locations, only: [:index, :show]
  resources :tags, only: [:index, :show]
  get "pages/about"
  get "pages/authentification"
  get "pages/account"
  get "pages/radio"
  get "pages/submit"
  get "pages/search"
  get "pages/contact"
  get "pages/webflow_migration"
  get "pages/song_promo"
  get "pages/licensing"
  get "pages/cookies"
  get "pages/privacy"
  # terms
  get '/term/licensing', to: redirect('/pages/licensing')
  get '/term/cookies', to: redirect('/pages/cookies')
  get '/term/privacy', to: redirect('/pages/privacy')
  get 'term/privacy-policy', to: redirect('/pages/privacy')
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  
  get '/:slug', to: redirect('/posts/%{slug}')
  get '/post/:slug', to: redirect('/posts/%{slug}')
  get '/about', to: redirect('/pages/about')
  get '/search', to: redirect('/pages/search')
  get '/contact', to: redirect('/pages/contact')
  get '/radio', to: redirect('/pages/radio')
  
  # random post
  get "posts/random", to: "posts#random"
  
  # find a way to re4solve old blog links with dates - chillfiltr.com/blog/2018/11/25/the-bull-brothers-high-time (TODO)

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end
