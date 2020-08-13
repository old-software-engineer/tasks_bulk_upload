# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
# get 'tracker/action', to: 'tracker_management_actions#new'
get 'tracker/actions', to: 'tracker_management_actions#index'
get 'tracker/options/:type', to: 'tracker_management_actions#options'
# post 'create/tracker/actions',to: 'tracker_management_actions#create'
post 'create/csvfile/tracker',to: 'tracker_management_actions#create_trecker'