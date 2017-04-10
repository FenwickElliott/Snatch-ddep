Rails.application.routes.draw do

  get 'snatch/about'
  get 'snatch/options'
  get 'snatch/link'

  get 'options' => 'snatch#options'
  get 'link' => 'snatch#link'

  root 'snatch#about'
end
