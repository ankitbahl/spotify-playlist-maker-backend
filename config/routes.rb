Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  # get '/login', to: 'application#login'
  get '/auth', to: 'application#auth_redirect'
  # get '/shuffle', to: 'application#shuffle'

end
