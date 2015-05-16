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
		@user = User.create(name: "empty", child_birthdate: "empty", time: "empty", phone: params[:From])
  		twiml = Twilio::TwiML::Response.new do |r|
   			r.Message "StoryTime: Thanks for signing up! Reply with your child's birthdate in MMYY format (e.g. 0912 for September 2013)."
    	end
    	twiml.text
    elsif @user.child_birthdate.eql? "empty" #update child's birthdate
    	@user.child_birthdate = params[:Body]
    	@user.save
  		twiml = Twilio::TwiML::Response.new do |r|
   			r.Message "StoryTime: Great! You've got free nightly stories by text. When do you want them? Reply with your preferred time and your child's name (e.g. 5:30pm Brianna)"
		end
 		twiml.text
 	elsif @user.time.eql? "empty" #update time 
 		response = params[:Body]
 		arr = response.split
 		@user.time = arr[0]
 		@user.name = arr[1]
    	@user.save
  		twiml = Twilio::TwiML::Response.new do |r|
   			r.Message "StoryTime: Sounds good! We'll send you and #{arr[1]} a new story each night at #{arr[0]}."
		end
 		twiml.text
	end
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


