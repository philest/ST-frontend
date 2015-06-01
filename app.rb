require 'sinatra'
require 'sinatra/activerecord'
require_relative './config/environments' #database configuration
require_relative './models/user' #add the user model
require 'twilio-ruby'
require 'sidekiq'
require 'sidetiq'
require 'redis'

require 'pry'

#REDIS initialization
require_relative './config/initializers/redis'

require 'sidekiq/api'

require_relative './sprint'
require_relative './age'

require_relative './workers/some_worker'

configure :production do
  require 'newrelic_rpm'
end

@@tips_normal = ["Thanks for continuing with StoryTime!\n\nEverytime your read or talk with your child, you're shaping a mind when it's growing most. You've already got all it takes!",
"Thanks again-- you're doing an awesome job!\n\nBeginning word sounds are essential for reading. You can help your child learn to
read by saying the beginning sound of words. \"Read\" starts w/ \"rrr\""]

@@tips_sprint = ["Thanks for continuing w/ StoryTime!\n\nEverytime your read or talk w/ your child, you're shaping a mind when it's growing most. You've already got all it takes!",
"Great, you're doing awesome!\n\nBeginning word sounds are essential for reading. You can help your child learn to
read by saying them. \"Read\" starts w/ \"rrr\""]



EMPTY_INT = 9999
EMPTY_STR = "empty"

HELP = "HELP NOW"
STOP = "STOP NOW"
TEXT = "TEXT"


RESUBSCRIBE = "StoryTime: Welcome back to StoryTime! Twice a week, we'll send you a new free story to read aloud-- continuing from where you left off!"

WRONG_BDAY_FORMAT = "We did not understand what you typed. Reply with child's birthdate in MMDDYY format. For questions, reply " + HELP + ". To cancel, reply " + STOP + "."

TOO_YOUNG_SMS = "StoryTime: Sorry, for now we only have msgs for kids ages 3 to 5. We'll contact you when we expand soon! Or reply with birthdate in MMYY format."

MMS_UPDATE = "Okay, you'll now receive just the text of each poem. Hope this works better!"

HELPSMS =  "StoryTime texts free kids' stories on Tues and Thurs. If you can't receive picture msgs, reply TEXT for text-only stories.

Remember that looking at screens within two hours of bedtime can delay children's sleep and carry health risks, so read StoryTime earlier in the day. 

Normal text rates may apply. For help or feedback, please contact our director, Phil, at 561-212-5831. Reply " + STOP + " to cancel."

HELP_SPRINT = "StoryTime texts free kids' stories on Tues and Thurs. For help or feedback, contact our director, Phil, at 561-212-5831. Reply " + STOP + " to cancel."

STOPSMS = "Okay, we\'ll stop texting you stories. Thanks for trying us out! If you have any feedback, please contact our director, Phil, at 561-212-5831."

STARTSMS = "StoryTime: Welcome to StoryTime, free kindergarten-prep stories by text! Twice a week, we\'ll send you and your child a new story to read aloud together-- starting tonight! 

Text " + HELP + " for help, or " + STOP + " to cancel."

START_SPRINT = "Welcome to StoryTime, free kindergarten-prep stories by text! We\'ll send you & your child two stories a week to read aloud together. Text HELP NOW for help."

TIME_SPRINT = "ST: Great, last question! When do you want to get stories (e.g. 5:00pm)? 

Screentime w/in 2hrs before bedtime can carry health risks, so please read earlier."

TIMESMS = "StoryTime: Great, last question! When do you want to receive stories (e.g. 5:00pm)? 

Screentime within 2hrs before bedtime can delay children's sleep and carry health risks, so please read earlier."

BAD_TIME_SMS = "We did not understand what you typed. Reply with your child's preferred time to receive stories (e.g. 5:00pm). 
For questions about StoryTime, reply " + HELP + ". To stop messages, reply " + STOP + "."
	
BAD_TIME_SPRINT = "We did not understand what you typed. Reply with your child's preferred time to receive stories (e.g. 5:00pm). Reply " + HELP + "for help."
	
REDO_BIRTHDATE = "When was your child born? For age appropriate stories, reply with your child's birthdate in MMYY format (e.g. 0912 for September 2012)."

SPRINT = "Sprint Spectrum, L.P."

NO_OPTION = "StoryTime: This service is automatic. We didn't understand what you typed. For questions about StoryTime, reply " + HELP + ". To stop messages, reply " + STOP + "."


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
		@user = User.create(child_name: EMPTY_STR, child_birthdate: EMPTY_STR, carrier: EMPTY_STR, phone: params[:From])


		#update subscription
		@user.update(subscribed: true) #Subscription complete! (B/C defaults)

    	# Lookup wireless carrier
    	#setup Twilio user account
   		account_sid = ENV['TW_ACCOUNT_SID']
    	auth_token = ENV['TW_AUTH_TOKEN']
	  	@client = Twilio::REST::LookupsClient.new account_sid, auth_token

	  	# Carrier Lookup
	  	number = @client.phone_numbers.get(@user.phone, type: 'carrier')
	  	@user.carrier = number.carrier['name']
	  	@user.save

	  	if @user.carrier == "Sprint Spectrum, L.P." 
			twiml = Twilio::TwiML::Response.new do |r|
	   			r.Message START_SPRINT #SEND SPRINT MSG
	    	end
	    	twiml.text
	    else
			twiml = Twilio::TwiML::Response.new do |r|
		   		r.Message STARTSMS
		    end
		    twiml.text
		end

	elsif @user.subscribed == false && params[:Body].casecmp("STORY") #if returning

			#REACTIVATE SUBSCRIPTION
			@user.update(subscribed: true)

			twiml = Twilio::TwiML::Response.new do |r|
		   		r.Message RESUBSCRIBE
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

		#change subscription
		@user.update(subscribed: false)

			twiml = Twilio::TwiML::Response.new do |r|
	   			r.Message STOPSMS
	    	end
	    	twiml.text


	elsif params[:Body].casecmp(TEXT) == 0 #TEXT option
		

		#change mms to sms
		@user.update(mms: false)

			twiml = Twilio::TwiML::Response.new do |r|
	   			r.Message MMS_UPDATE
	    	end
	    	twiml.text



	elsif params[:Body].casecmp("STORY") == 0 #texted STORY

		#undo birthdate
		 		@user.child_birthdate = EMPTY_STR
	 			@user.save

	 			@user.child_age = EMPTY_INT
	 			@user.save

	 			twiml = Twilio::TwiML::Response.new do |r|
	   				r.Message REDO_BIRTHDATE
				end
	 			twiml.text

	 			
	elsif /\A[1-5]{1}\z/ =~ params[:Body] #texted feedback 1 to 5.

			#SAVE FEEDBACK

			REDIS.zadd(@user.phone, @user.story_number - 1, params[:Body]) 
			#add the user's 1 to 5 feedback (value) to the story_number (key) of that night's story
			#in a sorted set by key of phonenumber;
			#EX: REDIS.zadd("+15612125831", 0, 5)  


			#UPDATE LAST FEEDBACK
			@user.update(last_feedback: @user.story_number - 1)

			#GIVE FEEDBACK! 

			#SPRINT
			if @user.carrier == SPRINT
	 			twiml = Twilio::TwiML::Response.new do |r|
	   				r.Message @@tips_sprint[@user.story_number - 1]
				end
	 			twiml.text				

	 		#NORMAL
	 		else 
	 			twiml = Twilio::TwiML::Response.new do |r|
	   				r.Message @@tips_normal[@user.story_number - 1]
				end
	 			twiml.text
	 		end

    # second reply: update child's birthdate
    elsif (@user.story_number == 4 || @user.story_number == 5) && /\A[0-9]{4}\z/ =~ params[:Body]
   		
		if /\A[0-9]{4}\z/ =~ params[:Body] #it's a stringified integer in proper MMDDYY format
  			
  			@user.child_birthdate = params[:Body]
  			@user.save

  			#add child's age
  			
  			ageFloat = Age.InYears(@user.child_birthdate)

  			if ageFloat < 3 && ageFloat >= 2.8 #let the older two's in.
  				ageFloat = 3
  			end


  			@user.child_age = ageFloat.to_i
  			@user.save

   			#give allow six year olds
 			if @user.child_age == 6 
  				@user.update(child_age: 5)
 			end



  			#check if in right age range
  			if @user.child_age <= 5 && @user.child_age >= 3 

  				@user.update(subscribed: true)
  				#redo subscription for parents who entered in bday wrongly

					TIME_SMS = "StoryTime: Great! Your child's birthdate is " + params[:Body][0,2] + "/" + params[:Body][2,2] + ". If not correct, reply STORY. If correct, enjoy your next age-appropriate story!"

		 			twiml = Twilio::TwiML::Response.new do |r|
		   				r.Message TIME_SMS
		  				end
		 			twiml.text

	 		else #Wrong age rage

	 			@user.update(subscribed: false)

	 			#NOTE: Keep the real birthdate.
	 			twiml = Twilio::TwiML::Response.new do |r|
	   				r.Message TOO_YOUNG_SMS
				end
	 			twiml.text
	 		end

	    else #not a valid format
  			twiml = Twilio::TwiML::Response.new do |r|
   				r.Message WRONG_BDAY_FORMAT
			end
 			twiml.text
		end 	

 	# Update TIME before (or after) third story
 	elsif (@user.story_number == 2 || @user.story_number == 3) && /[:apm]/ =~ params[:Body]
 		
 		response = params[:Body]
 		arr = response.split

 		if arr.length == 1 || arr.length == 2 #plausible format
 			if arr.length == 1
 				if /\A[0-9]{1,2}[:][0-9]{2}[ap][m]\z/ =~ arr[0]
 					@user.time = arr[0]
		 			@user.save

		  			twiml = Twilio::TwiML::Response.new do |r|
		   				r.Message "StoryTime: Sounds good! Your new story time is #{@user.time}-- enjoy!"
					end
		 			twiml.text

 				else

					#if sprint
					if @user.carrier == "Sprint Spectrum, L.P." 

						twiml = Twilio::TwiML::Response.new do |r|
				   			r.Message BAD_TIME_SPRINT #SEND SPRINT MSG
				    	end
				    	twiml.text

					else #not Sprint

						twiml = Twilio::TwiML::Response.new do |r|
				   			r.Message BAD_TIME_SMS	#SEND NORMAL
				    	end
				    	twiml.text
					end

 				end

 			else
 				if /\A[0-9]{1,2}[:][0-9]{2}\z/ =~ arr[0] && /\A[ap][m]\z/ =~ arr[1]
 					@user.time = arr[0] + arr[1]
		 			@user.save


		  			twiml = Twilio::TwiML::Response.new do |r|
		   				r.Message "StoryTime: Sounds good! Your new story time is #{@user.time}-- enjoy!"
					end
		 			twiml.text 					
 				else

					#if sprint
					if @user.carrier == "Sprint Spectrum, L.P." 

						twiml = Twilio::TwiML::Response.new do |r|
				   			r.Message BAD_TIME_SPRINT #SEND SPRINT MSG
				    	end
				    	twiml.text

					else #not Sprint

						twiml = Twilio::TwiML::Response.new do |r|
				   			r.Message BAD_TIME_SMS	#SEND NORMAL
				    	end
				    	twiml.text
					end

 				end
 				
 			end

 		else #wrong format
					#if sprint
					if @user.carrier == "Sprint Spectrum, L.P." 

						twiml = Twilio::TwiML::Response.new do |r|
				   			r.Message BAD_TIME_SPRINT #SEND SPRINT MSG
				    	end
				    	twiml.text

					else #not Sprint

						twiml = Twilio::TwiML::Response.new do |r|
				   			r.Message BAD_TIME_SMS	#SEND NORMAL
				    	end
				    	twiml.text
					end
 		end
 		
	#response matches nothing
	else
		twiml = Twilio::TwiML::Response.new do |r|
   			r.Message NO_OPTION
		end
 		twiml.text
		# raise "something broke-- message was not regeistered"
	end
end





















#THIS IS SIMPLY FOR TESTING! UPDATED MAY 30. 

get '/test/:From/:Body/:Carrier' do
	#check if new user
	#returns nil if not found
	@user = User.find_by_phone(params[:From]) 

	if @user != nil #if user exists
		@user.update(carrier: params[:Carrier]) 
	end

	#first reply: new user, add her
	if @user == nil 
		@user = User.create(child_name: EMPTY_STR, child_birthdate: EMPTY_STR, carrier: EMPTY_STR, phone: params[:From])


		#update subscription
		@user.update(subscribed: true) #Subscription complete! (B/C defaults)

    	# udpate wireless carrier
    	@user.update(carrier: params[:Carrier])


	  	if @user.carrier == SPRINT

	   			@@twiml = START_SPRINT #SEND SPRINT MSG
	    else
				@@twiml = STARTSMS
		end


	elsif @user.subscribed == false && params[:Body].casecmp("STORY") #if returning

		@user.update(subscribed: true)
		@@twiml = RESUBSCRIBE

	elsif params[:Body].casecmp(HELP) == 0 #HELP option
		

		#if sprint
		if @user.carrier == SPRINT

			@@twiml = HELP_SPRINT

		else #not Sprint

			@@twiml = HELPSMS

		end

	elsif params[:Body].casecmp(STOP) == 0 #STOP option

		#change subscription
		@user.update(subscribed: false)

	   		@@twiml = STOPSMS


	elsif params[:Body].casecmp(TEXT) == 0 #TEXT option
		

		#change mms to sms
		@user.update(mms: false)

	   		@@twiml = MMS_UPDATE


	elsif params[:Body].casecmp("STORY") == 0 #texted STORY

		#undo birthdate
		 		@user.child_birthdate = EMPTY_STR
	 			@user.save

	 			@user.child_age = EMPTY_INT
	 			@user.save

	   			@twiml = REDO_BIRTHDATE

	 			
	elsif /\A[1-5]{1}\z/ =~ params[:Body] #texted feedback 1 to 5.

			# **DONT** SAVE FEEDBACK

			# REDIS.zadd(@user.phone, @user.story_number - 1, params[:Body]) 
			#add the user's 1 to 5 feedback (value) to the story_number (key) of that night's story
			#in a sorted set by key of phonenumber;
			#EX: REDIS.zadd("+15612125831", 0, 5)  


			#UPDATE LAST FEEDBACK
			@user.update(last_feedback: @user.story_number - 1)

			#GIVE FEEDBACK! 
			if @user.carrier == SPRINT
				@@twiml = @@tips_sprint[@user.story_number - 1]
	 		#NORMAL
	 		else 
		   		@@twiml = @@tips_normal[@user.story_number - 1]
	 		end

    # second reply: update child's birthdate
    elsif (@user.story_number == 4 || @user.story_number == 5) && /\A[0-9]{4}/ =~ params[:Body]
   	
    



		if /\A[0-9]{4}\z/ =~ params[:Body] #it's a stringified integer in proper MMDDYY format
  			
  			@user.child_birthdate = params[:Body]
  			@user.save

  			#add child's age
  			
  			ageFloat = Age.InYears(@user.child_birthdate)

  			if ageFloat < 3 && ageFloat >= 2.8 #let the older two's in.
  				ageFloat = 3
  			end


  			@user.child_age = ageFloat.to_i
  			@user.save

   			#give allow six year olds
 			if @user.child_age == 6 
  				@user.update(child_age: 5)
 			end



  			#check if in right age range
  			if @user.child_age <= 5 && @user.child_age >= 3 

  				@user.update(subscribed: true)
  				#redo subscription for parents who entered in bday wrongly

					TIME_SMS = "StoryTime: Great! Your child's birthdate is " + params[:Body][0,2] + "/" + params[:Body][2,2] + ". If not correct, reply STORY. If correct, enjoy your next age-appropriate story!"

		   			@@twiml = TIME_SMS


	 		else #Wrong age rage

	 			@user.update(subscribed: false)

	 			#NOTE: Keep the real birthdate.
	   			@@twiml =  TOO_YOUNG_SMS
	 		end

	    else #not a valid format
   			@@twiml =  WRONG_BDAY_FORMAT
		end 	

 	# Update TIME before (or after) third story
 	elsif (@user.story_number == 2 || @user.story_number == 3) && /[:apm]/ =~ params[:Body]
 	
 	

 		response = params[:Body]
 		arr = response.split

 		if arr.length == 1 || arr.length == 2 #plausible format
 			if arr.length == 1
 				if /\A[0-9]{1,2}[:][0-9]{2}[ap][m]\z/ =~ arr[0]
 					@user.update(time: arr[0])

		   				@@twiml = "StoryTime: Sounds good! Your new story time is #{@user.time}-- enjoy!"

 				else

					#if sprint
					if @user.carrier == SPRINT

				   			@@twiml = BAD_TIME_SPRINT #SEND SPRINT MSG

					else #not Sprint

				   			@@twiml = BAD_TIME_SMS	#SEND NORMAL
					end

 				end

 			else
 				if /\A[0-9]{1,2}[:][0-9]{2}\z/ =~ arr[0] && /\A[ap][m]\z/ =~ arr[1]
 					@user.time = arr[0] + arr[1]
		 			@user.save


		   				@@twiml = "StoryTime: Sounds good! Your new story time is #{@user.time}-- enjoy!"
 				else

					#if sprint
					if @user.carrier == SPRINT 

				   			@@twiml = BAD_TIME_SPRINT #SEND SPRINT MSG

					else #not Sprint

				   			@@twiml = BAD_TIME_SMS	#SEND NORMAL
					end

 				end
 				
 			end

 		else #wrong format
					#if sprint
					if @user.carrier == "Sprint Spectrum, L.P." 

				   			@@twiml = BAD_TIME_SPRINT #SEND SPRINT MSG

					else #not Sprint

				   			@@twiml = BAD_TIME_SMS #SEND SPRINT MSG
					end
 		end
 		
	#response matches nothing
	else
		

   			@@twiml = NO_OPTION
		# raise "something broke-- message was not regeistered"
	end
end












# # TESTING ROUTE!!!!
# get '/test/:From/:Body' do
# 	#check if new user
# 	#returns nil if not found
# 	@user = User.find_by_phone(params[:From]) 
	

# 	#first reply: new user, add her
# 	if @user == nil 
# 		@user = User.create(child_name: EMPTY_STR, child_birthdate: EMPTY_STR, time: EMPTY_STR, phone: params[:From])
#   		@@twiml = "StoryTime: Thanks for signing up! Reply with your child's age in years (e.g. 3)."


# 	elsif params[:Body].casecmp("HELP") == 0 #HELP option
		
# 		#if sprint
# 		if @user.carrier == "Sprint Spectrum, L.P." 

# 			smsArr = Sprint.chop(HELPSMS)
			
# 			smsArr.each do |text|
# 				@@twiml.push(text)
# 	            # sleep 2
# 			end

# 		else #not Sprint

# 			@@twiml = HELPSMS
		
# 		end
#     # second reply: update child's birthdate
#     elsif @user.child_birthdate == EMPTY_STR
		

# 		if /\A[0-9]{6}\z/ =~ params[:Body] #it's a stringified integer
#   			@user.child_birthdate = params[:Body]
#   			@user.save
# 	       	@@twiml = "StoryTime: Great! You've got free nightly stories. Reply with your preferred time to receive stories (e.g. 6:30pm)"
	    
# 	    # elsif numberNames.include? params[:Body] #the number is spelled out as name
# 	    # 	@user.child_age = params[:Body].in_numbers
#   			# @user.save
# 	    #    	@@twiml = "StoryTime: Great! You've got free nightly stories. Reply with your child's name and your preferred time to receive stories (e.g. Brianna 5:30pm)"

# 	    else #not a valid format
#    			@@twiml = "We did not understand what you typed. Please reply with your child's birthdate in MMDDYY format. For questions about StoryTime, reply HELP. To Stop messages, reply STOP."
# 		end 	
 

#  	# third reply: update time and child's name
#  	elsif @user.time.eql? EMPTY_STR


#  		response = params[:Body]
#  		arr = response.split

# 	 	if arr.length == 1 || arr.length == 2 #plausible format
# 	 		if arr.length == 1
# 		 		#handle wrong order
#  				if /\A[0-9]{1,2}[:][0-9]{2}[ap][m]\z/  =~ arr[0]
# 		 			@user.time = arr[0]
# 		 			@user.save
# 		 			@@twiml = "StoryTime: Sounds good! We'll send you and your child a new story each night at #{@user.time}."
# 		 		else
# 		   			@@twiml = "(1/2)We did not understand what you typed. Reply with your child's preferred time to receive stories (e.g. 6:30pm)."
# 		 		end
# 		 	else 
#  				if /\A[0-9]{1,2}[:][0-9]{2}\z/ =~ arr[0] && /\A[ap][m]\z/ =~ arr[1]
# 					@user.time = arr[0] + arr[1]
# 		 			@user.save					
# 					@@twiml = "StoryTime: Sounds good! We'll send you and your child a new story each night at #{@user.time}."

# 		 		else
# 		   			@@twiml = "(1/2)We did not understand what you typed. Reply with your child's preferred time to receive stories (e.g. 6:30pm)."
# 		 		end
# 		 	end
 		
# 	 	else #wrong format
#    				@@twiml = "(1/2)We did not understand what you typed. Reply with your child's preferred time to receive stories (e.g. 6:30pm)."
# 	 	end

# 	#response matches nothing
# 	else
#   		@@twiml = "StoryTime: This service is automatic. We did not understand what you typed. For questions about StoryTime, reply HELP NOW. To stop messages, reply STOP NOW."
# 		# raise "something broke-- message was not regeistered"
# 	end
# end








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


