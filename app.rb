require 'sinatra'
require 'sinatra/activerecord'
require './config/environments' #database configuration
require './models/user' #add the user model
require 'twilio-ruby'
require 'numbers_in_words'
require 'numbers_in_words/duck_punch'
require 'sidekiq'
require 'sidetiq'
require 'redis'
require 'sidekiq/api'

require './workers/some_worker'


EMPTY_INT = 999
EMPTY_STR = "empty"
numberNames = ['zero','one','two','three','four','five','six','seven','eight','nine','ten']





get '/worker' do
	SomeWorker.perform #begin sidetiq recurrring background tasks
	redirect to('/')
end

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
		@user = User.create(child_name: EMPTY_STR, child_birthdate: EMPTY_STR, time: EMPTY_STR, phone: params[:From])
  		twiml = Twilio::TwiML::Response.new do |r|
   			r.Message "StoryTime: Thanks for signing up! When was your child born? Reply with your child's birthdate in MMDDYY format (e.g. 091412 for Septempber 14, 2012)."
    	end
    	twiml.text

    # second reply: update child's birthdate
    elsif @user.child_birthdate == EMPTY_STR 
   		

		if /\A[0-9]{6}\z/ =~ params[:Body] #it's a stringified integer in proper MMDDYY format
  			@user.child_birthdate = params[:Body]
  			@user.save
  			twiml = Twilio::TwiML::Response.new do |r|
   				r.Message "StoryTime: Great! You've got free nightly stories. Reply with your preferred time to receive stories (e.g. 6:30pm)"
			end
 			twiml.text
	    
	  #   elsif numberNames.include? params[:Body] #the number is spelled out as name
	  #   	@user.child_age = params[:Body].in_numbers
  	# 		@user.save
  	# 		twiml = Twilio::TwiML::Response.new do |r|
   # 				r.Message "StoryTime: Great! You've got free nightly stories. Reply with your child's name and your preferred time to receive stories (e.g. Brianna 5:30pm)"
			# end
 		# 	twiml.text
	    else #not a valid format
  			twiml = Twilio::TwiML::Response.new do |r|
   				r.Message "We did not understand what you typed. Reply with your child's birthdate in MMDDYY format. For questions about StoryTime, reply HELP. To Stop messages, reply STOP."
			end
 			twiml.text
		end 	

 	# third reply: update time and child's name
 	elsif @user.time == EMPTY_STR
 		
 		response = params[:Body]
 		arr = response.split

 		if arr.length == 1 || arr.length == 2 #plausible format
 			if arr.length == 1
 				if /\A[0-9]{1,2}[:][0-9]{2}[ap][m]\z/ =~ arr[0]
 					@user.time = arr[0]

		 			@user.save
		  			twiml = Twilio::TwiML::Response.new do |r|
		   				r.Message "StoryTime: Sounds good! We'll send you and your child a new story each night at #{@user.time}."
					end
		 			twiml.text

 				else
 					twiml = Twilio::TwiML::Response.new do |r|
		   				r.Message "(1/2)We did not understand what you typed. Reply with your child's preferred time to receive stories (e.g. 5:30pm)."
					end
		 			twiml.text
			 		twiml = Twilio::TwiML::Response.new do |r|
		   				r.Message "(2/2)For questions about StoryTime, reply HELP. To Stop messages, reply STOP."
					end
		 			twiml.text
 				end
 			else
 				if /\A[0-9]{1,2}[:][0-9]{2}\z/ =~ arr[0] && /\A[ap][m]\z/ =~ arr[1]
 					@user.time = arr[0] + arr[1]

		 			@user.save
		  			twiml = Twilio::TwiML::Response.new do |r|
		   				r.Message "StoryTime: Sounds good! We'll send you and your child a new story each night at #{@user.time}."
					end
		 			twiml.text 					
 				else
 					twiml = Twilio::TwiML::Response.new do |r|
		   				r.Message "(1/2)We did not understand what you typed. Reply with your child's preferred time to receive stories (e.g. 5:30pm)."
					end
		 			twiml.text
			 		twiml = Twilio::TwiML::Response.new do |r|
		   				r.Message "(2/2)For questions about StoryTime, reply HELP. To Stop messages, reply STOP."
					end
		 			twiml.text
 				end
 			end


 		else #wrong format
 			twiml = Twilio::TwiML::Response.new do |r|
		   		r.Message "(1/2)We did not understand what you typed. Reply with your child's preferred time to receive stories (e.g. 5:30pm)."
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
		@user = User.create(child_name: EMPTY_STR, child_birthdate: EMPTY_STR, time: EMPTY_STR, phone: params[:From])
  		@@twiml = "StoryTime: Thanks for signing up! Reply with your child's age in years (e.g. 3)."


    # second reply: update child's birthdate
    elsif @user.child_birthdate == EMPTY_STR
		

		if /\A[0-9]{6}\z/ =~ params[:Body] #it's a stringified integer
  			@user.child_birthdate = params[:Body]
  			@user.save
	       	@@twiml = "StoryTime: Great! You've got free nightly stories. Reply with your preferred time to receive stories (e.g. 6:30pm)"
	    
	    # elsif numberNames.include? params[:Body] #the number is spelled out as name
	    # 	@user.child_age = params[:Body].in_numbers
  			# @user.save
	    #    	@@twiml = "StoryTime: Great! You've got free nightly stories. Reply with your child's name and your preferred time to receive stories (e.g. Brianna 5:30pm)"

	    else #not a valid format
   			@@twiml = "We did not understand what you typed. Please reply with your child's birthdate in MMDDYY format. For questions about StoryTime, reply HELP. To Stop messages, reply STOP."
		end 	
 

 	# third reply: update time and child's name
 	elsif @user.time.eql? EMPTY_STR


 		response = params[:Body]
 		arr = response.split

	 	if arr.length == 1 || arr.length == 2 #plausible format
	 		if arr.length == 1
		 		#handle wrong order
 				if /\A[0-9]{1,2}[:][0-9]{2}[ap][m]\z/  =~ arr[0]
		 			@user.time = arr[0]
		 			@user.save
		 			@@twiml = "StoryTime: Sounds good! We'll send you and your child a new story each night at #{@user.time}."
		 		else
		   			@@twiml = "(1/2)We did not understand what you typed. Reply with your child's preferred time to receive stories (e.g. 6:30pm)."
		 		end
		 	else 
 				if /\A[0-9]{1,2}[:][0-9]{2}\z/ =~ arr[0] && /\A[ap][m]\z/ =~ arr[1]
					@user.time = arr[0] + arr[1]
		 			@user.save					
					@@twiml = "StoryTime: Sounds good! We'll send you and your child a new story each night at #{@user.time}."

		 		else
		   			@@twiml = "(1/2)We did not understand what you typed. Reply with your child's preferred time to receive stories (e.g. 6:30pm)."
		 		end
		 	end
 		
	 	else #wrong format
   				@@twiml = "(1/2)We did not understand what you typed. Reply with your child's preferred time to receive stories (e.g. 6:30pm)."
	 	end

	#response matches nothing
	else
  		@@twiml = "This service is automatic. We did not understand what you typed. For questions about StoryTime, reply HELP. To Stop messages, reply STOP."
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

# get '/users/new/:phone' do
# 	# add user to db
# 	@user = User.create(name: "empty", phone: params[:phone])
# 	erb :new
# end


