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
  post '/copy/:id' => 'de_settings#copy', :as => :copy

  get '/degust', to: redirect('/')

  # Routes for degust app
  scope '/degust' do
    # Default API for /degust
    resources :degust, only: [], path: '' do
      member do
        get 'settings'
        post 'settings' => 'degust#save_settings'
        get 'partial_csv'
        get 'csv'
        get 'dge'
        get 'dge_r_code'
        get 'kegg_titles'
        resources :gene_lists, param: :gene_list_id
      end
    end

    # Versioned API
    constraints version: /[^\/]+/ do
      scope 'version/:version/' do
        resources :degust, only: [], path: '' do
          member do
            get 'settings'
            post 'settings' => 'degust#save_settings'
            get 'partial_csv'
            get 'csv'
            get 'dge'
            get 'dge_r_code'
            get 'kegg_titles'
            resources :gene_lists, param: :gene_list_id
          end
        end
        get '*page' => 'degust#static', :as => :degust_page_version
      end
    end  # End version constraint

    # General calls
    get '/kegg/*page' => 'degust#static_kegg'
    get '/*page' => 'degust#static', :as => :degust_page

  end # End /degust scope

end
