require 'sinatra'
require 'sinatra/activerecord'
require './config/environments' #database configuration
require './models/user' #add the user model
require 'twilio-ruby'

get '/' do
	erb :main
end

# register an incoming SMS
get '/sms' do
	#check if new user
	#returns nil if not found
	@user = User.find_by_phone(params[:From]) 

	if @user == nil #new user, add her
		@user = User.create(name: "empty", phone: params[:From])
  		twiml = Twilio::TwiML::Response.new do |r|
   			r.Message "Thanks ya jew- You've got StoryTime JSC!"
    	end
    	twiml.text
    elsif @user.name.eql? "empty" #update name
    	@user.name = params[:Body]
    	@user.save
    end 




  @user = User.create(name: "empty", phone: params[:From])
  twiml = Twilio::TwiML::Response.new do |r|
    r.Message "Thanks ya jew- You've got StoryTime JSC!"
  end
  twiml.text
end




	#add user to db
# 	@user = User.create(name: "empty", phone: params[:From])
# 	twiml = Twilio::TwiML::Response.new do |r|
#     	r.Message "Thanks for signing up for StoryTime!"
#   	end
#   	twiml.text
# end

get '/users/new/:phone' do
	# add user to db
	@user = User.create(name: "empty", phone: params[:phone])
	erb :new
end


