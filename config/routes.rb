#
#  This file is part of TSDBExplorer.
#
#  TSDBExplorer is free software: you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation, either version 3 of the License, or (at your
#  option) any later version.
#
#  TSDBExplorer is distributed in the hope that it will be useful, but
#  WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
#  Public License for more details.
#
#  You should have received a copy of the GNU General Public License along
#  with TSDBExplorer.  If not, see <http://www.gnu.org/licenses/>.
#
#  $Id: routes.rb 108 2011-04-19 20:25:19Z pwh $
#

Tsdbexplorer::Application.routes.draw do

  devise_for :users, :skip => [:sessions]

  as :user do
    get "login" => "devise/sessions#new", :as => :new_user_session
    post "login" => "devise/sessions#create", :as => :user_session
    get "logout" => "devise/sessions#destroy", :as => :destroy_user_session
  end

  root :to => "main#index"

  match '/healthcheck', :controller => 'healthcheck', :action => 'index'

  match '/location/search', :controller => 'location', :action => 'search'
  match '/location/advanced_search', :controller => 'location', :action => 'advanced_search'

#  match '/location/:location/from/:from/to/:to/:year/:month/:day/:time', :controller => 'location', :action => 'index'
#  match '/location/:location/from/:from/to/:to/:year/:month/:day', :controller => 'location', :action => 'index'
#  match '/location/:location/from/:from/:year/:month/:day/:time', :controller => 'location', :action => 'index'
#  match '/location/:location/from/:from/:year/:month/:day', :controller => 'location', :action => 'index'
#  match '/location/:location/to/:to/:year/:month/:day/:time', :controller => 'location', :action => 'index'
#  match '/location/:location/to/:to/:year/:month/:day', :controller => 'location', :action => 'index'
#  match '/location/:location/:year/:month/:day/:time', :controller => 'location', :action => 'index'
#  match '/location/:location/:year/:month/:day', :controller => 'location', :action => 'index'

  match '/location/:location', :controller => 'location', :action => 'index'

  match '/schedule/search', :controller => 'schedule', :action => 'search'
  match '/schedule/:uid/:year/:month/:day', :controller => 'schedule', :action => 'schedule_by_uid_and_run_date'
  match '/schedule/:uid', :controller => 'schedule', :action => 'schedule_by_uid'

  match '/actual/:uuid', :controller => 'schedule', :action => 'actual'

  match '/about', :controller => 'main', :action => 'about'
  match '/disclaimer', :controller => 'main', :action => 'disclaimer'

  match '/session/set/:key/:value', :controller => 'session', :action => 'set'
  match '/session/clear/:key', :controller => 'session', :action => 'clear'
  match '/session/toggle/:key', :controller => 'session', :action => 'toggle'
  match '/session/toggle_on/:key', :controller => 'session', :action => 'toggle_on'
  match '/session/toggle_off/:key', :controller => 'session', :action => 'toggle_off'

  match '/live/station/:tiploc', :controller => 'live', :action => 'stations_updates_json'

  match ':controller(/:action(/:id(.:format)))'

end
