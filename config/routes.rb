Robotomate::Application.routes.draw do
  post "event/subscribe/:uuid" => 'event#subscribe'
  get "event/poll/:uuid" => 'event#poll'

  if Rails.env == "development" || Rails.env == "test"
    get "event/subscribe" # debug
    get "event/debug/:uuid" => 'event#debug'
  end

  match 'device/all_on' => 'device#all_on'
  match 'device/all_off' => 'device#all_off'
  match 'device/create' => 'device#create'
  match 'device/edit/:id' => 'device#edit'
  match 'device/:id/on' => 'device#on'
  match 'device/:id/off' => 'device#off'
  match 'device/:id/dim_to' => 'device#dim_to'
  match 'device/' => 'device#index'
  put 'device/create_or_update' => 'device#create_or_update'
  post 'device/create_or_update' => 'device#create_or_update'

  if Rails.env == "development" || Rails.env == "test"
    match 'test/qunit_data_loader' => 'test#qunit_data_loader'
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'device#index'

  # Resque admin interface
  if Rails.env != "test"
    mount Resque::Server.new, :at => "/resque"
  end
  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
