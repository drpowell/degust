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

  get '/degust', to: redirect('/')

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

  # Specific Version routes - don't know the rails way to do this...
  constraints version: /[^\/]+/ do
    get '/degust/version/:version/:id/settings' => 'degust#settings'
    post '/degust/version/:version/:id/settings' => 'degust#save_settings'
    get '/degust/version/:version/:id/partial_csv' => 'degust#partial_csv'
    get '/degust/version/:version/:id/csv' => 'degust#csv'
    get '/degust/version/:version/:id/dge' => 'degust#dge'
    get '/degust/version/:version/:id/dge_r_code' => 'degust#dge_r_code'
    get '/degust/version/:version/:id/kegg_titles' => 'degust#kegg_titles'
    get '/degust/version/:version/kegg/*page' => 'degust#static_kegg'
    get '/degust/version/:version/*page' => 'degust#static', :as => :degust_page_version
  end

  # General calls
  get '/degust/kegg/*page' => 'degust#static_kegg'
  get '/degust/*page' => 'degust#static', :as => :degust_page
end
