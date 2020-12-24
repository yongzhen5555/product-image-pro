Rails.application.routes.draw do
  root to: 'home#index'
  mount ShopifyApp::Engine, at: '/'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get 'products/:id' => 'home#index'
  namespace :api do
    namespace :v1 do
      resources :products
    end
  end
end
