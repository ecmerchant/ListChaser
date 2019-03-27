require 'resque/server'

Rails.application.routes.draw do

  get 'yahoo_auc_searches/setup'
  post 'yahoo_auc_searches/setup'

  get 'prices/edit'
  post 'prices/edit'

  get 'lists/show'
  post 'lists/show'

  get 'rakuten_searches/setup'
  post 'rakuten_searches/setup'

  get 'list_templates/setup'
  post 'list_templates/setup'

  get 'products/check'
  post 'products/check'
  get 'products/csv_download'


  get 'accounts/setup'
  post 'accounts/setup'

  get 'items/search'
  post 'items/search'
  post 'items/select'

  root to: 'items#search'

  mount Resque::Server.new, at: "/resque"

  devise_scope :user do
    get '/users/sign_out' => 'devise/sessions#destroy'
    get '/sign_in' => 'devise/sessions#new'
  end

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  devise_for :users, :controllers => {
   :registrations => 'users/registrations'
  }

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
