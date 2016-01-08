Wrestling::Application.routes.draw do
  resources :mats

  resources :matches

  devise_for :users
  
  resources :tournaments

  resources :schools

  resources :weights

  resources :wrestlers

  post "/weights/:id" => "weights#show"

  

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'static_pages#home'
  get 'admin/index'
  get 'static_pages/control_match'
  get 'static_pages/not_allowed'
  get 'static_pages/about'
  get 'static_pages/my_tournaments'

  get 'tournaments/:id/weigh_in/:weight'  => 'tournaments#weigh_in_weight'
  post 'tournaments/:id/weigh_in/:weight'  => 'tournaments#weigh_in_weight'
  get 'tournaments/:id/weigh_in'  => 'tournaments#weigh_in'
  get 'tournaments/:id/create_custom_weights' => 'tournaments#create_custom_weights'
  get 'tournaments/:id/all_brackets' => 'tournaments#all_brackets'
  get 'tournaments/:id/brackets' => 'tournaments#brackets'
  get 'tournaments/:id/brackets/:weight' => 'tournaments#bracket'
  get 'tournaments/:id/generate_matches' => 'tournaments#generate_matches'
  get 'tournaments/:id/team_scores' => 'tournaments#team_scores'
  get 'tournaments/:id/up_matches' => 'tournaments#up_matches'
  get 'tournaments/:id/no_matches' => 'tournaments#no_matches'
  get 'tournaments/:id/matches' => 'tournaments#matches'
  get 'tournaments/:id/delegate' => 'tournaments#delegate', :as => :tournament_delegate
  post 'tournaments/:id/delegate' => 'tournaments#delegate', :as => :set_tournament_delegate
  delete 'tournaments/:id/:delegate/remove_delegate' => 'tournaments#remove_delegate', :as => :delete_delegate_path
  get 'tournaments/:id/school_delegate' => 'tournaments#school_delegate', :as => :school_delegate
  post 'tournaments/:id/school_delegate' => 'tournaments#school_delegate', :as => :set_school_delegate
  delete 'tournaments/:id/:delegate/remove_school_delegate' => 'tournaments#remove_school_delegate', :as => :delete_school_delegate_path
  
  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
