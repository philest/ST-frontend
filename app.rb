require 'sinatra'
require 'sinatra/activerecord'
require './config/environments' #database configuration
require './models/user' #add the user model
require 'twilio-ruby'

EMPTY_AGE = 999


get '/' do
	erb :main
end

# register an incoming SMS
get '/sms' do
	#check if new user
	#returns nil if not found
	@user = User.find_by_phone(params[:From]) 

	if @user == nil #new user, add her
		@user = User.create(child_name: "empty", child_age: EMPTY_AGE, time: "empty", phone: params[:From])
  		twiml = Twilio::TwiML::Response.new do |r|
   			r.Message "StoryTime: Thanks for signing up! Reply with your child's age in years (e.g. 3)."
    	end
    	twiml.text
    elsif @user.child_age == EMPTY_AGE #update child's birthdate
    	@user.child_age = Integer(params[:Body])
    	@user.save
  		twiml = Twilio::TwiML::Response.new do |r|
   			r.Message "StoryTime: Great! You've got free nightly stories. Reply with your child's name and your preferred time to receive stories (e.g. Brianna 5:30pm)"
		end
 		twiml.text
 	elsif @user.time.eql? "empty" #update time and child's name
 		response = params[:Body]
 		arr = response.split

 		if arr.length == 2
	 		#handle wrong order
	 		if arr[0] =~ [A-Za-z] #the first element is the name
	 			@user.name = arr[0]
	 			@user.time = arr[1]
	 		else
	 			@user.time = arr[0]
	 			@user.name = arr[1]
	 		end
	 	elsif arr.length == 3
	 		if arr[0] =~ [A-Za-z] #the first element is the name
	 			@user.name = arr[0]
	 			@user.time = arr[1] + arr[2]
	 		else
	 			@user.time = arr[0] + arr[1]
	 			@user.name = arr[2]
	 		end
	 	else
	 		raise "this format is incorrect. try again"
	 	end

    	@user.save
  		twiml = Twilio::TwiML::Response.new do |r|
   			r.Message "StoryTime: Sounds good! We'll send you and #{@user.name} a new story each night at #{@user.time}."
		end
 		twiml.text
	else
		twiml = Twilio::TwiML::Response.new do |r|
   			r.Message "Something broke-- response when not given a prompt."
		end
 		twiml.text
		raise "something broke-- message was not regeistered"
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


