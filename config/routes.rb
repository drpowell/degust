Rails.application.routes.draw do
  resources :users
  root to: 'visitors#index'
  get '/auth/:provider/callback' => 'sessions#create'
  get '/signin' => 'sessions#new', :as => :signin
  get '/signout' => 'sessions#destroy', :as => :signout
  get '/auth/failure' => 'sessions#failure'

  resources :de_settings
  get '/visited' => 'de_settings#index'
  get '/upload' => 'de_settings#new'
  post '/upload' => 'de_settings#create'

  # Routes for degust app
  resources :degust, only: [] do
    member do
      get 'settings'
      post 'settings' => 'degust#save_settings'
      get 'partial_csv'
      get 'csv'
      get 'dge'
      get 'dge_r_code'
      get 'kegg_titles'
    end
  end
  get '/degust/kegg/*page' => 'degust#static_kegg'
  get '/degust/*page' => 'degust#static', :as => :degust_page
end
