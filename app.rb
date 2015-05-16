require 'sinatra'
require 'sinatra/activerecord'
require './config/environments' #database configuration
require './models/user' #add the user model
require 'twilio-ruby'

get '/' do
	erb :main
end

# register an incoming SMS
post '/' do
	#add user to db
	@user = User.create(name: "empty", phone: params[:From])
	twiml = Twilio::TwiML::Response.new do |r|
    	r.Message "Thanks for signing up for StoryTime!"
  	end
  	twiml.text
end

get '/users/new/:phone' do
	# add user to db
	@user = User.create(name: "empty", phone: params[:phone])
	erb :new
end


