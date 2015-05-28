require 'sinatra'
require 'sinatra/activerecord'
require './config/environments' #database configuration
require './models/user' #add the user model
require 'twilio-ruby'
require 'sidekiq'
require 'sidetiq'
require 'redis'
require 'sidekiq/api'

require './sprint'
require './age'

require './workers/some_worker'

configure :production do
  require 'newrelic_rpm'
end

@@quiters = Array.new #people who have left (STOP)

EMPTY_INT = 999
EMPTY_STR = "empty"

HELP = "HELP NOW"
STOP = "STOP NOW"

HELPSMS =  "StoryTime texts free kids' stories. For help or feedback, please contact our director, Phil, at 561-212-5831.

Remember that looking at screens within two hours of bedtime can delay children's sleep and carry health risks, so read StoryTime earlier in the day. 

Normal text rates may apply. StoryTime sends 2 msgs/week. Reply " +STOP+ " to cancel."


HELP_SPRINT = "StoryTime texts free kids' stories twice/week. For help or feedback, contact our director, Phil, at 561-212-5831. Reply " + STOP + " to cancel."


STOPSMS = "Okay, we'll stop texting you stories. Thanks for trying us out! Please contact our director, Phil, at 561-212-5831 if you have any feedback."

STARTSMS = 
"Welcome to StoryTime, free stories by text! When was your child born? Reply with birthdate in MMDDYY format (e.g. 091412 for Septempber 14, 2012)."


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
		@user = User.create(child_name: EMPTY_STR, child_birthdate: EMPTY_STR, time: EMPTY_STR, carrier: EMPTY_STR, phone: params[:From])

    	# Lookup wireless carrier
    	#setup Twilio user account
   		account_sid = ENV['TW_ACCOUNT_SID']
    	auth_token = ENV['TW_AUTH_TOKEN']
	  	@client = Twilio::REST::LookupsClient.new account_sid, auth_token

	  	# Carrier Lookup
	  	number = @client.phone_numbers.get(@user.phone, type: 'carrier')
	  	@user.carrier = number.carrier['name']
	  	@user.save


		twiml = Twilio::TwiML::Response.new do |r|
	   		r.Message STARTSMS
	    end
	    twiml.text
		


	elsif params[:Body].casecmp(HELP) == 0 #HELP option
		
		#if sprint
		if @user.carrier == "Sprint Spectrum, L.P." 

			twiml = Twilio::TwiML::Response.new do |r|
	   			r.Message HELP_SPRINT #SEND SPRINT MSG
	    	end
	    	twiml.text

		else #not Sprint

			twiml = Twilio::TwiML::Response.new do |r|
	   			r.Message HELPSMS	#SEND NORMAL
	    	end
	    	twiml.text

		end

	elsif params[:Body].casecmp(STOP) == 0 #STOP option
		
		#add to ended list
		@@quiters.push @user

		#delete user
		@user.delete

			twiml = Twilio::TwiML::Response.new do |r|
	   			r.Message STOPSMS
	    	end
	    	twiml.text


    # second reply: update child's birthdate
    elsif @user.child_birthdate == EMPTY_STR 
   		

		if /\A[0-9]{6}\z/ =~ params[:Body] #it's a stringified integer in proper MMDDYY format
  			
  			@user.child_birthdate = params[:Body]
  			@user.save

  			#add child's age
  			@user.child_age = Age.InYears(@user.child_birthdate)
  			@user.save

  			#check if in right age range
  			if @user.child_age <= 5 && @user.child_age >= 3 
	  			twiml = Twilio::TwiML::Response.new do |r|
	   				r.Message "(1/2) StoryTime: Great! You've got free nightly stories. Reply with your preferred time to receive stories (e.g. 5:00pm)"
	   				r.Message "(2/2) Remember that looking at screens within two hours of bedtime can delay children's sleep and carry health risks, so read StoryTime earlier in the day."
				end
	 			twiml.text

	 		else #Wrong age rage

	 			@user.child_birthdate = EMPTY_STR
	 			@user.save

	 			@user.child_age = EMPTY_INT
	 			@user.save

	 			twiml = Twilio::TwiML::Response.new do |r|
	   				r.Message "StoryTime: Sorry, for now we only sends msgs for kids ages 3 to 5. We'll contact you when we expand! Reply with child's birthdate in MMDDYY format."
				end
	 			twiml.text
	 		end

	    else #not a valid format
  			twiml = Twilio::TwiML::Response.new do |r|
   				r.Message "We did not understand what you typed. Reply with your child's birthdate in MMDDYY format. For questions about StoryTime, reply " + HELP + ". To Stop messages, reply STOP."
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
		   				r.Message "(1/2)We did not understand what you typed. Reply with your child's preferred time to receive stories (e.g. 5:00pm)."
						r.Message "(2/2)For questions about StoryTime, reply " + HELP + ". To Stop messages, reply " + STOP + "."
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
		   				r.Message "(2/2)For questions about StoryTime, reply " + HELP + ". To Stop messages, reply STOP."
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
		   		r.Message "(2/2)For questions about StoryTime, reply " + HELP + ". To Stop messages, reply STOP."
			end
		 	twiml.text
 		end
 		
	#response matches nothing
	else
		twiml = Twilio::TwiML::Response.new do |r|
   			r.Message "This service is automatic. We did not understand what you typed. For questions about StoryTime, reply " + HELP + ". To Stop messages, reply STOP."
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


	elsif params[:Body].casecmp("HELP") == 0 #HELP option
		
		#if sprint
		if @user.carrier == "Sprint Spectrum, L.P." 

			smsArr = Sprint.chop(HELPSMS)
			
			smsArr.each do |text|
				@@twiml.push(text)
	            # sleep 2
			end

		else #not Sprint

			@@twiml = HELPSMS
		
		end
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


