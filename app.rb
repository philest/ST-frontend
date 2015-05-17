require 'sinatra'
require 'sinatra/activerecord'
require './config/environments' #database configuration
require './models/user' #add the user model
require 'twilio-ruby'
require 'numbers_in_words'
require 'numbers_in_words/duck_punch'

EMPTY_INT = 999
EMPTY_STR = "empty"

get '/' do
	erb :main
end


# register an incoming SMS
get '/sms' do
	#check if new user
	#returns nil if not found
	@user = User.find_by_phone(params[:From]) 
	

	#first reply: new user, add her
	if @user == nil 
		@user = User.create(child_name: EMPTY_STR, child_age: EMPTY_INT, time: EMPTY_STR, phone: params[:From])
  		twiml = Twilio::TwiML::Response.new do |r|
   			r.Message "StoryTime: Thanks for signing up! Reply with your child's age in years (e.g. 3)."
    	end
    	twiml.text

    # second reply: update child's birthdate
    elsif @user.child_age == EMPTY_INT 
   		
    	# if a valid age (integer or word spelled out)
    	if params[:Body].is_a? Integer or params[:Body].in_numbers
    		
    		if params[:Body].is_a? Integer 
    			@user.child_age = Integer(params[:Body])
       		else #it's a word
       			@user.child_age =  params[:Body].in_numbers
       		end

	       	@user.save
	  		twiml = Twilio::TwiML::Response.new do |r|
	   			r.Message "StoryTime: Great! You've got free nightly stories. Reply with your child's name and your preferred time to receive stories (e.g. Brianna 5:30pm)"
			end
 			twiml.text

   		else #not a real number
   			twiml = Twilio::TwiML::Response.new do |r|
   				r.Message "We did not understand what you typed. Please reply with your child's age in years. For questions about StoryTime, reply HELP. To Stop messages, reply STOP."
			end
 			twiml.text
 		end 	

 	# third reply: update time and child's name
 	elsif @user.time.eql? EMPTY_STR
 		
 		response = params[:Body]
 		arr = response.split

	 	if arr.length == 2 or arr.length == 3 #plausible format
	 		if arr.length == 2
		 		#handle wrong order
		 		if /[A-Za-z]/ =~ arr[0]#the first element is the name
		 			@user.name = arr[0]
		 			@user.time = arr[1]
		 		else
		 			@user.time = arr[0]
		 			@user.name = arr[1]
		 		end
		 	elsif arr.length == 3
		 		if /[A-Za-z]/ =~ arr[0] #the first element is the name
		 			@user.name = arr[0]
		 			@user.time = arr[1] + arr[2]
		 		else
		 			@user.time = arr[0] + arr[1]
		 			@user.name = arr[2]
		 		end
		 	end

			@user.save
  			twiml = Twilio::TwiML::Response.new do |r|
   				r.Message "StoryTime: Sounds good! We'll send you and #{@user.name} a new story each night at #{@user.time}."
			end
 			twiml.text
 		
	 	else #wrong format
	 		twiml = Twilio::TwiML::Response.new do |r|
   				r.Message "(1/2)We did not understand what you typed. Reply with your child's name and your preferred time to receive stories (e.g. Brianna 5:30pm)."
			end
 			twiml.text
	 		twiml = Twilio::TwiML::Response.new do |r|
   				r.Message "(2/2)For questions about StoryTime, reply HELP. To Stop messages, reply STOP."
			end
 			twiml.text
	 	end

	#response matches nothing
	else
		twiml = Twilio::TwiML::Response.new do |r|
   			r.Message "This service is automatic. We did not understand what you typed. For questions about StoryTime, reply HELP. To Stop messages, reply STOP."
		end
 		twiml.text
		# raise "something broke-- message was not regeistered"
	end
end









# TESTING ROUTE!!!!
get '/test/:From/:Body' do
	#check if new user
	#returns nil if not found
	@user = User.find_by_phone(params[:From]) 
	

	#first reply: new user, add her
	if @user == nil 
		@user = User.create(child_name: EMPTY_STR, child_age: EMPTY_INT, time: EMPTY_STR, phone: params[:From])
  		@twiml = "StoryTime: Thanks for signing up! Reply with your child's age in years (e.g. 3)."

  		


    # second reply: update child's birthdate
    elsif @user.child_age == EMPTY_INT 
   		
    	# if a valid age (integer or word spelled out)
    	if params[:Body].is_a? Integer or params[:Body].in_numbers
    		
    		if params[:Body].is_a? Integer 
    			@user.child_age = Integer(params[:Body])
       		else #it's a word
       			@user.child_age =  params[:Body].in_numbers
       		end

	       	@user.save
	       	@twiml = "StoryTime: Great! You've got free nightly stories. Reply with your child's name and your preferred time to receive stories (e.g. Brianna 5:30pm)"

   		else #not a real number
   			@twiml = "We did not understand what you typed. Please reply with your child's age in years. For questions about StoryTime, reply HELP. To Stop messages, reply STOP."
 		end 	

 	# third reply: update time and child's name
 	elsif @user.time.eql? EMPTY_STR
 		
 		response = params[:Body]
 		arr = response.split

	 	if arr.length == 2 or arr.length == 3 #plausible format
	 		if arr.length == 2
		 		#handle wrong order
		 		if /[A-Za-z]/ =~ arr[0]#the first element is the name
		 			@user.name = arr[0]
		 			@user.time = arr[1]
		 		else
		 			@user.time = arr[0]
		 			@user.name = arr[1]
		 		end
		 	elsif arr.length == 3
		 		if /[A-Za-z]/ =~ arr[0] #the first element is the name
		 			@user.name = arr[0]
		 			@user.time = arr[1] + arr[2]
		 		else
		 			@user.time = arr[0] + arr[1]
		 			@user.name = arr[2]
		 		end
		 	end

   				@twiml = "StoryTime: Sounds good! We'll send you and #{@user.name} a new story each night at #{@user.time}."
 		
	 	else #wrong format
   				@twiml = "(1/2)We did not understand what you typed. Reply with your child's name and your preferred time to receive stories (e.g. Brianna 5:30pm)."
	 	end

	#response matches nothing
	else
  		@twiml = "This service is automatic. We did not understand what you typed. For questions about StoryTime, reply HELP. To Stop messages, reply STOP."
		# raise "something broke-- message was not regeistered"
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


