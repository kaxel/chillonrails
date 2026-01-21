Rails.application.routes.draw do
  resources :playlists, path: 'playlist', param: :slug, only: [:show]
  get "errors/not_found"
  get "errors/internal_server_error"
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
  resource :session, only: [:new, :destroy]
  get 'auth/:provider/callback', to: 'omniauth_callbacks#google_oauth2'
  post 'auth/:provider/callback', to: 'omniauth_callbacks#google_oauth2'
  get 'auth/failure', to: 'omniauth_callbacks#failure'
  resources :posts, path: 'post', param: :slug, only: [:edit, :show, :update]
  get 'posts/feed', to: 'posts#feed', defaults: { format: 'rss' }
  get 'posts/last', to: 'posts#last', defaults: { format: 'rss' }
  resources :locations, only: [:index, :show]
  resources :tags, path: 'tag', param: :slug, only: [:index, :show]
  get 'authors', to: 'authors#index'
  resources :authors, path: 'author', param: :slug, only: [:show]
  
  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
        
  get "pages/about"
  get "pages/authentication"
  get "pages/account"
  get "pages/radio"
  get '/submit', to: redirect('/pages/submit')
  get "pages/submit"
  get "pages/search"
  get "pages/contact"
  get "pages/webflow_migration"
  get "pages/song_promo"
  get "pages/licensing"
  get "pages/terms"
  get "pages/cookies", to: "pages#cookie_policy"
  get "pages/privacy"
  get "pages/support"
  get "pages/archive"
  
  #redirect old story links to search page
  get "story/:slug", to: redirect('/pages/search?search=tell+me+a+story')
  
  # terms
  get '/term/licensing', to: redirect('/pages/licensing')
  get '/term/cookies', to: redirect('/pages/cookies')
  get '/term/privacy', to: redirect('/pages/privacy')
  get '/term/terms', to: redirect('/pages/terms')
  get 'term/privacy-policy', to: redirect('/pages/privacy')
  
  # review,/topic/prose
  get "/review", to: redirect("/?topic=prose")
  
  get "/topic/music", to: redirect("/?topic=music")
  get "/topic/personal", to: redirect("/?topic=personal")
  get "/topic/lifestyle", to: redirect("/?topic=lifestyle")
  get "/topic/technology", to: redirect("/?topic=technology")
  
  get '/about', to: redirect('/pages/about')
  get '/search', to: redirect('/pages/search')
  get '/contact', to: redirect('/pages/contact')
  get '/radio', to: redirect('/pages/radio')
  get '/promo', to: redirect('/pages/song-promo')
  get '/support', to: redirect('/pages/support')
  get '/product/song-submission', to: redirect('/pages/submit')
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  
  get '/:slug', to: redirect('/post/%{slug}')
  get 'posts/:slug', to: redirect('/post/%{slug}')
  
  # random post
  get "posts/random", to: "post#random"
  
  
  
  # Old blog format redirects to new post format
  get '/blog/:year/:month/:day/:slug', to: redirect('/post/%{slug}')

  # Suppress Chrome DevTools error
  get "/.well-known/appspecific/com.chrome.devtools.json" => proc { [204, {}, []] }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end
