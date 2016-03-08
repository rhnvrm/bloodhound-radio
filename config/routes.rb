Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'welcome#index'

  get '/auth/soundcloud/callback', to: 'users#authenticate'

  resources :users do
    get 'authenticate', on: :collection
    get 'deauthenticate', on: :collection
  end
end
