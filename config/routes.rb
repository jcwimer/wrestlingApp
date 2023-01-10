Wrestling::Application.routes.draw do
  resources :mats
  post "mats/:id/assign_next_match" => "mats#assign_next_match", :as => :assign_next_match

  resources :matches

  devise_for :users

  resources :tournaments

  resources :schools

  resources :weights

  resources :wrestlers

  post "/weights/:id" => "weights#show"
  post "weights/:id/pool_order" => "weights#pool_order"

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'static_pages#home'
  get 'static_pages/control_match'
  get 'static_pages/not_allowed'
  get 'static_pages/about'
  get 'static_pages/my_tournaments'
  get 'static_pages/tutorials'

  get 'tournaments/:id/weigh_in_sheet' => 'tournaments#weigh_in_sheet'
  get 'tournaments/:id/weigh_in/:weight'  => 'tournaments#weigh_in_weight'
  post 'tournaments/:id/weigh_in/:weight'  => 'tournaments#weigh_in_weight'
  get 'tournaments/:id/weigh_in'  => 'tournaments#weigh_in'
  get 'tournaments/:id/create_custom_weights' => 'tournaments#create_custom_weights'
  get 'tournaments/:id/all_brackets' => 'tournaments#all_brackets'
  get 'tournaments/:id/brackets/:weight' => 'tournaments#bracket', :as => :weight_bracket
  get 'tournaments/:id/generate_matches' => 'tournaments#generate_matches'
  get 'tournaments/:id/team_scores' => 'tournaments#team_scores'
  get 'tournaments/:id/up_matches' => 'tournaments#up_matches', :as => :up_matches
  get 'tournaments/:id/bout_sheets' => 'tournaments#bout_sheets'
  get 'tournaments/:id/no_matches' => 'tournaments#no_matches'
  get 'tournaments/:id/matches' => 'tournaments#matches'
  get 'tournaments/:id/delegate' => 'tournaments#delegate', :as => :tournament_delegate
  post 'tournaments/:id/delegate' => 'tournaments#delegate', :as => :set_tournament_delegate
  delete 'tournaments/:id/:delegate/remove_delegate' => 'tournaments#remove_delegate', :as => :delete_delegate_path
  get 'tournaments/:id/school_delegate' => 'tournaments#school_delegate', :as => :school_delegate
  post 'tournaments/:id/school_delegate' => 'tournaments#school_delegate', :as => :set_school_delegate
  delete 'tournaments/:id/:delegate/remove_school_delegate' => 'tournaments#remove_school_delegate', :as => :delete_school_delegate_path
  get 'tournaments/:id/teampointadjust' => 'tournaments#teampointadjust'
  post 'tournaments/:id/teampointadjust' => 'tournaments#teampointadjust'
  delete 'tournaments/:id/:teampointadjust/remove_teampointadjust' => 'tournaments#remove_teampointadjust'
  get 'tournaments/:id/error' => 'tournaments#error'
  post "/tournaments/:id/swap" => "tournaments#swap", :as => :swap_wrestlers
  get 'tournaments/:id/export' => "tournaments#export"
  post "/tournaments/:id/import" => "tournaments#import", :as => :import  
  get "/tournaments/:id/brackets" => "tournaments#show"
  put "/tournaments/:id/calculate_team_scores", :to => "tournaments#calculate_team_scores"

  post 'weights/:id/re_gen' => 'weights#re_gen', :as => :regen_weight
  post "/wrestlers/update_pool" => "wrestlers#update_pool"

  get "schools/:id/stats" => "schools#stats"
  post "/schools/:id/import_baumspage_roster" => "schools#import_baumspage_roster", :as => :import_baumspage_roster
  
  #API
  get "/api/tournaments" => "api#tournaments"
  get "/api/tournaments/user" => "api#currentUserTournaments"
  get "/api/tournaments/:tournament" => "api#tournament"
  get "/api/index" => "api#index"
  post "/api/tournaments/new" => "newTournament"

  match "/delayed_job" => DelayedJobWeb, :anchor => false, :via => [:get, :post]

  get "/matches/:id/stat" => "matches#stat", :as => :stat_match_path

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
