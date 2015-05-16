require 'sinatra'
require 'sinatra/activerecord'
require './config/environments' #database configuration
require './models/user' #add the user model

get '/' do
	erb :main
end

# post '/users/new/:name' do