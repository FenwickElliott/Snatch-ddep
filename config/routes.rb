Rails.application.routes.draw do

  devise_for :users
  get 'snatch/about'
  get 'snatch/options'
  get 'snatch/link'
  get 'snatch/fail'

  get 'options' => 'snatch#options'
  get 'link' => 'snatch#link'
  get 'fail' => 'snatch#fail'

  get '/auth/:provider/callback', to: 'snatch#link'
  get '/auth/failure' , to: 'snatch#fail'

  root 'snatch#about'
end
