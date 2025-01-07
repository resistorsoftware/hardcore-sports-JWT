Rails.application.routes.draw do
  root to: 'home#index'

  get '/home', to: 'home#index'
  get "/order", to: "order#index"
  resource :orders, only: :show

  mount ShopifyApp::Engine, at: '/'
end
