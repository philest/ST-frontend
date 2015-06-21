require 'sinatra'
require 'sinatra/activerecord'
require_relative './config/environments' #database configuration
require_relative './models/user' #add the user model
require 'twilio-ruby'
require 'sidekiq'
require 'sidetiq'
require 'redis'

#REDIS initialization
require_relative './config/initializers/redis'

require 'sidekiq/api'
require_relative './sprint'
require_relative './age'

require_relative './message'
require_relative './messageSeries'
require_relative './workers/some_worker'
require_relative './workers/first_text_worker'
require_relative './workers/choice_worker'
require_relative './helpers.rb'

#require the testing workers
# configure :test, :development do
# 	require_relative './workers/test/test_some_worker'
# end


configure :production do
  require 'newrelic_rpm'
end

HELP = "HELP NOW"
STOP = "STOP NOW"
TEXT = "TEXT"


RESUBSCRIBE = "StoryTime: Welcome back to StoryTime! Twice a week, we'll send you a new free story to read aloud-- continuing from where you left off!"

WRONG_BDAY_FORMAT = "We did not understand what you typed. Reply with child's birthdate in MMDDYY format. For questions, reply " + HELP + ". To cancel, reply " + STOP + "."

TOO_YOUNG_SMS = "StoryTime: Sorry, for now we only have msgs for kids ages 3 to 5. We'll contact you when we expand soon! Or reply with birthdate in MMYY format."

MMS_UPDATE = "Okay, you'll now receive just the text of each story. Hope this helps!"

HELP_SMS_1 =  "StoryTime texts free kids' stories on "

HELP_SMS_2 = ". If you can't receive picture msgs, reply TEXT for text-only stories.

Remember that looking at screens within two hours of bedtime can delay children's sleep and carry health risks, so read StoryTime earlier in the day. 

Normal text rates may apply. For help or feedback, please contact our director, Phil, at 561-212-5831. Reply " + STOP + " to cancel."

HELP_SPRINT_1 = "StoryTime texts free kids' stories on "

HELP_SPRINT_2 = ". For help or feedback, contact our director, Phil, at 561-212-5831. Reply " + STOP + " to cancel."


STOPSMS = "Okay, we\'ll stop texting you stories. Thanks for trying us out! If you have any feedback, please contact our director, Phil, at 561-212-5831."

START_SMS_1 = "StoryTime: Welcome to StoryTime, free pre-k stories by text! You'll get "

START_SMS_2 = " stories/week-- the first is on the way!\n\nText " + HELP + " for help, or " + STOP + " to cancel."

START_SPRINT_1 = "Welcome to StoryTime, free pre-k stories by text! You'll get "

START_SPRINT_2 = " stories/week-- the 1st is on the way!\n\nFor help, reply HELP NOW."


TIME_SPRINT = "ST: Great, last question! When do you want to get stories (e.g. 5:00pm)? 

Screentime w/in 2hrs before bedtime can carry health risks, so please read earlier."

TIMESMS = "StoryTime: Great, last question! When do you want to receive stories (e.g. 5:00pm)? 

Screentime within 2hrs before bedtime can delay children's sleep and carry health risks, so please read earlier."

BAD_TIME_SMS = "We did not understand what you typed. Reply with your preferred time to get stories (e.g. 5:00pm). 
For questions about StoryTime, reply " + HELP + ". To stop messages, reply " + STOP + "."
	
BAD_TIME_SPRINT = "We did not understand what you typed. Reply with your preferred time to get stories (e.g. 5:00pm). Reply " + HELP + "for help."
	
REDO_BIRTHDATE = "When was your child born? For age appropriate stories, reply with your child's birthdate in MMYY format (e.g. 0912 for September 2012)."

SPRINT = "Sprint Spectrum, L.P."

NO_OPTION = "StoryTime: This service is automatic. We didn't understand what you typed. For questions about StoryTime, reply " + HELP + ". To stop messages, reply " + STOP + "."

GOOD_CHOICE = "Great, it's on the way!"

BAD_CHOICE = "StoryTime: Sorry, we didn't understand that. Reply with the letter of the story you want.

For help, reply HELP NOW."

POST_SAMPLE = "StoryTime: Hi! StoryTime's an automated service, but, if you want to learn more, contact our director, Phil, at 561-212-5831."

NO_SIGNUP_MATCH = "StoryTime: Sorry, we didn't understand that. Text STORY to signup for free stories by text, or text SAMPLE to receive a sample"

SAMPLE = "SAMPLE"

EXAMPLE = "EXAMPLE"

FIRST = "FIRST"

GREET_SMS  = "StoryTime: Thanks for trying out StoryTime, free stories by text! Your two page sample story is on the way :)"


PRO = "production"
TEST = "test"

get '/worker' do
	SomeWorker.perform_async #begin sidetiq recurrring background tasks
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

	mode = PRO
	
	#first reply: new user texts in STORY
	if params[:Body].casecmp("STORY") == 0 && (@user == nil || @user.sample == true)

		if @user == nil
			@user = User.create(phone: params[:From])
		else
			@user.update(sample: false)
			@user.update(subscribed: true) 
		end

		if mode == PRO #only relevant for production code
			#randomly assign to get two days a week or three days a week
			if (rand = Random.rand(9)) == 0
				@user.update(days_per_week: 3)
			elsif rand < 5
				@user.update(days_per_week: 1)
			else
				@user.update(days_per_week: 2)
			end
		else
			@user.update(days_per_week: 2)
		end

			#update subscription
			@user.update(subscribed: true) #Subscription complete! (B/C defaults)
			#backup for defaults
			@user.update(time: "5:30pm", child_age: 4)

			if mode == PRO
				#TWILIO set up:
		   		account_sid = ENV['TW_ACCOUNT_SID']
		    	auth_token = ENV['TW_AUTH_TOKEN']
			  	@client = Twilio::REST::LookupsClient.new account_sid, auth_token

		    	# Lookup wireless carrier
			  	number = @client.phone_numbers.get(@user.phone, type: 'carrier')
			  	@user.update(carrier: number.carrier['name'])
		  	else
		  		@user.update(carrier: params[:Carrier])
		  	end


		  	days = @user.days_per_week.to_s

			FirstTextWorker.perform_in(15.seconds, mode, FIRST, @user.phone)
			
		  	Helpers.text(mode, START_SMS_1 + days + START_SMS_2, START_SPRINT_1 + days + START_SPRINT_2, @user.phone)	


	elsif @user == nil && (params[:Body].casecmp("SAMPLE") == 0 || params[:Body].casecmp("EXAMPLE") == 0)

		@user = User.create(sample: true, subscribed: false, phone: params[:From])

		FirstTextWorker.perform_async(mode, params[:Body].upcase, params[:From])

	elsif @user == nil

		Helpers.text(mode, NO_SIGNUP_MATCH, NO_SIGNUP_MATCH, params[:From])

	elsif @user.sample == true

		Helpers.text(mode, POST_SAMPLE, POST_SAMPLE, @user.phone)

	elsif @user.subscribed == false && params[:Body].casecmp("STORY") == 0 #if returning

		#REACTIVATE SUBSCRIPTION
		@user.update(subscribed: true)
		@user.update(next_index_in_series: nil)

		Helpers.text(mode, RESUBSCRIBE, RESUBSCRIBE, @user.phone)

	elsif params[:Body].casecmp(HELP) == 0 #HELP option
		
	  	#default 2 days a week
	  	if @user.days_per_week == nil
	  		@user.update(days_per_week: 2)
	  	end

	  	#find the day names
	  	case @user.days_per_week
	  	when 1
	  		dayNames = "Wed"
	  	when 2, nil
	  		dayNames = "Tues and Thurs"
	  	when 3
	  		dayNames = "Mon Wed & Fri"
	  	else
	  		puts "ERR: invalid days of week"
	  	end

	  	Helpers.text(mode, HELP_SMS_1 + dayNames + HELP_SMS_2, HELP_SPRINT_1 + dayNames + HELP_SPRINT_2, @user.phone)


	elsif params[:Body].casecmp(STOP) == 0 #STOP option
		
		if mode == PRO
		#SAVE QUITTERS
			REDIS.set(@user.phone+":quit", "true") 
			#update if the user quits
			#EX: REDIS.zadd("+15612125831:quit", true)  
		end

		#change subscription
		@user.update(subscribed: false)

		Helpers.text(mode, STOPSMS, STOPSMS, @user.phone)

	elsif params[:Body].casecmp(TEXT) == 0 #TEXT option		

		#change mms to sms
		@user.update(mms: false)

		Helpers.text(mode, MMS_UPDATE, MMS_UPDATE, @user.phone)

	elsif params[:Body].casecmp("REDO") == 0 #texted STORY

		#no need to manually undo birthdate
		Helpers.text(mode, REDO_BIRTHDATE, REDO_BIRTHDATE, @user.phone)

	#Responds with a letter when prompted to choose a series
	#Account for quotations
	elsif @user.awaiting_choice == true && /\A[']{0,1}["]{0,1}[a-zA-Z][']{0,1}["]{0,1}\z/ =~ params[:Body]			
		
		body = params[:Body]

		#has quotations => extract the juicy part
		if  !(/\A[a-zA-Z]\z/ =~ params[:Body])
			body = params[:Body][1,1]
		end

		body.downcase!

		#push back to zero incase this was changed to -1 to denote one 'day' after
        @user.update(next_index_in_series: 0)

		#check if the choice is valid
		if MessageSeries.codeIsInHash( body + @user.series_number.to_s)
	 			
			#update the series choice
			@user.update(series_choice: body)
			@user.update(awaiting_choice: false)

			ChoiceWorker.perform_async(mode, @user.phone)

	 	else	 			
			Helpers.text(mode, BAD_CHOICE, BAD_CHOICE, @user.phone)
	 	end				


    # second reply: update child's birthdate
    elsif @user.set_birthdate == false && /[0-9]{4}/ =~ params[:Body]
   		
		if /\A[0-9]{4}\z/ =~ params[:Body] #it's a stringified integer in proper MMYY format
  			
  			@user.update(child_birthdate: params[:Body])

  			#add child's age
  			ageFloat = Age.InYears(@user.child_birthdate)

  			if ageFloat < 3 && ageFloat >= 2.8 #let the older two's in.
  				ageFloat = 3
  			end

  			@user.update(child_age: ageFloat.to_i)

   			# allow six year olds
 			if @user.child_age == 6 
  				@user.update(child_age: 5)
 			end

  			#check if in right age range
  			if @user.child_age <= 5 && @user.child_age >= 3 

  				#redo subscription for parents who entered in bday wrongly
  				@user.update(subscribed: true)
  				@user.update(set_birthdate: true)

					time_sms = "StoryTime: Great! Your child's birthdate is " + params[:Body][0,2] + "/" + params[:Body][2,2] + ". If not correct, reply REDO. If correct, enjoy your next age-appropriate story!"

					Helpers.text(mode, time_sms, time_sms, @user.phone)

	 		else #Wrong age rage

	 			@user.update(subscribed: false)

	 			#NOTE: Keep the real birthdate.
	 			Helpers.text(mode, TOO_YOUNG_SMS, TOO_YOUNG_SMS, @user.phone)

	 		end

	    else #not a valid format
	  		Helpers.text(mode, WRONG_BDAY_FORMAT, WRONG_BDAY_FORMAT, @user.phone)
		end 	

 	# Update TIME before (or after) third story
 	elsif @user.set_time == false && /(:|pm|am)/ =~ params[:Body]
 		
 		response = params[:Body]
 		arr = response.split

 		case arr.length
 		when 1

			if /\A[0-9]{1,2}[:][0-9]{2}[ap][m]\z/ =~ arr[0]
				
				@user.update(time: arr[0]) 
		        #They've set their own time, so don't ask again
		        @user.update(set_time: true)

				good_time = "StoryTime: Sounds good! Your new story time is #{@user.time}. Enjoy!"

					Helpers.text(mode, good_time, good_time, @user.phone)
			else
			
				Helpers.text(mode, BAD_TIME_SMS, BAD_TIME_SPRINT, @user.phone)
			end

		when 2
 				if /\A[0-9]{1,2}[:][0-9]{2}\z/ =~ arr[0] && /\A[ap][m]\z/ =~ arr[1]
 					
 					@user.update(time: arr[0] + arr[1])

 					#They've set their own time, so don't ask again
			        @user.update(set_time: true)


					good_time = "StoryTime: Sounds good! Your new story time is #{@user.time}. Enjoy!"
					
					Helpers.text(mode, good_time, good_time, @user.phone)

 				else
					
					Helpers.text(mode, BAD_TIME_SMS, BAD_TIME_SPRINT, @user.phone)

 				end
 		else 
		
			Helpers.text(mode, BAD_TIME_SMS, BAD_TIME_SPRINT, @user.phone)

		end

	#response matches nothing
	else

		Helpers.text(mode, NO_OPTION, NO_OPTION, @user.phone)

	end

end

















#THIS IS SIMPLY FOR TESTING! UPDATED JUNE 12. 

get '/test/:From/:Body/:Carrier' do

	#check if new user
	#returns nil if not found
	@user = User.find_by_phone(params[:From])

	mode = TEST
	
	
	#first reply: new user texts in STORY
	if params[:Body].casecmp("STORY") == 0 && (@user == nil || @user.sample == true)

		if @user == nil
			@user = User.create(phone: params[:From])
		else
			@user.update(sample: false)
			@user.update(subscribed: true) 
		end

		if mode == PRO #only relevant for production code
			#randomly assign to get two days a week or three days a week
			if (rand = Random.rand(9)) == 0
				@user.update(days_per_week: 3)
			elsif rand < 5
				@user.update(days_per_week: 1)
			else
				@user.update(days_per_week: 2)
			end
		else
			@user.update(days_per_week: 2)
		end

			#update subscription
			@user.update(subscribed: true) #Subscription complete! (B/C defaults)
			#backup for defaults
			@user.update(time: "5:30pm", child_age: 4)

			if mode == PRO
				#TWILIO set up:
		   		account_sid = ENV['TW_ACCOUNT_SID']
		    	auth_token = ENV['TW_AUTH_TOKEN']
			  	@client = Twilio::REST::LookupsClient.new account_sid, auth_token

		    	# Lookup wireless carrier
			  	number = @client.phone_numbers.get(@user.phone, type: 'carrier')
			  	@user.update(carrier: number.carrier['name'])
		  	else
		  		@user.update(carrier: params[:Carrier])
		  	end


		  	days = @user.days_per_week.to_s

			FirstTextWorker.perform_in(15.seconds, mode, FIRST, @user.phone)
			
		  	Helpers.text(mode, START_SMS_1 + days + START_SMS_2, START_SPRINT_1 + days + START_SPRINT_2, @user.phone)	


	elsif @user == nil && (params[:Body].casecmp("SAMPLE") == 0 || params[:Body].casecmp("EXAMPLE") == 0)

		@user = User.create(sample: true, subscribed: false, phone: params[:From])

		FirstTextWorker.perform_async(mode, params[:Body].upcase, params[:From])

	elsif @user == nil

		Helpers.text(mode, NO_SIGNUP_MATCH, NO_SIGNUP_MATCH, params[:From])

	elsif @user.sample == true

		Helpers.text(mode, POST_SAMPLE, POST_SAMPLE, @user.phone)

	elsif @user.subscribed == false && params[:Body].casecmp("STORY") == 0 #if returning

		#REACTIVATE SUBSCRIPTION
		@user.update(subscribed: true)
		@user.update(next_index_in_series: nil)

		Helpers.text(mode, RESUBSCRIBE, RESUBSCRIBE, @user.phone)

	elsif params[:Body].casecmp(HELP) == 0 #HELP option
		
	  	#default 2 days a week
	  	if @user.days_per_week == nil
	  		@user.update(days_per_week: 2)
	  	end

	  	#find the day names
	  	case @user.days_per_week
	  	when 1
	  		dayNames = "Wed"
	  	when 2, nil
	  		dayNames = "Tues and Thurs"
	  	when 3
	  		dayNames = "Mon Wed & Fri"
	  	else
	  		puts "ERR: invalid days of week"
	  	end

	  	Helpers.text(mode, HELP_SMS_1 + dayNames + HELP_SMS_2, HELP_SPRINT_1 + dayNames + HELP_SPRINT_2, @user.phone)


	elsif params[:Body].casecmp(STOP) == 0 #STOP option
		
		if mode == PRO
		#SAVE QUITTERS
			REDIS.set(@user.phone+":quit", "true") 
			#update if the user quits
			#EX: REDIS.zadd("+15612125831:quit", true)  
		end

		#change subscription
		@user.update(subscribed: false)

		Helpers.text(mode, STOPSMS, STOPSMS, @user.phone)

	elsif params[:Body].casecmp(TEXT) == 0 #TEXT option		

		#change mms to sms
		@user.update(mms: false)

		Helpers.text(mode, MMS_UPDATE, MMS_UPDATE, @user.phone)

	elsif params[:Body].casecmp("REDO") == 0 #texted STORY

		#no need to manually undo birthdate
		Helpers.text(mode, REDO_BIRTHDATE, REDO_BIRTHDATE, @user.phone)

	#Responds with a letter when prompted to choose a series
	#Account for quotations
	elsif @user.awaiting_choice == true && /\A[']{0,1}["]{0,1}[a-zA-Z][']{0,1}["]{0,1}\z/ =~ params[:Body]			
		
		body = params[:Body]

		#has quotations => extract the juicy part
		if  !(/\A[a-zA-Z]\z/ =~ params[:Body])
			body = params[:Body][1,1]
		end

		body.downcase!

		#push back to zero incase this was changed to -1 to denote one 'day' after
        @user.update(next_index_in_series: 0)

		#check if the choice is valid
		if MessageSeries.codeIsInHash( body + @user.series_number.to_s)
	 			
			#update the series choice
			@user.update(series_choice: body)
			@user.update(awaiting_choice: false)

			ChoiceWorker.perform_async(mode, @user.phone)

	 	else	 			
			Helpers.text(mode, BAD_CHOICE, BAD_CHOICE, @user.phone)
	 	end				


    # second reply: update child's birthdate
    elsif @user.set_birthdate == false && /[0-9]{4}/ =~ params[:Body]
   		
		if /\A[0-9]{4}\z/ =~ params[:Body] #it's a stringified integer in proper MMYY format
  			
  			@user.update(child_birthdate: params[:Body])

  			#add child's age
  			ageFloat = Age.InYears(@user.child_birthdate)

  			if ageFloat < 3 && ageFloat >= 2.8 #let the older two's in.
  				ageFloat = 3
  			end

  			@user.update(child_age: ageFloat.to_i)

   			# allow six year olds
 			if @user.child_age == 6 
  				@user.update(child_age: 5)
 			end

  			#check if in right age range
  			if @user.child_age <= 5 && @user.child_age >= 3 

  				#redo subscription for parents who entered in bday wrongly
  				@user.update(subscribed: true)
  				@user.update(set_birthdate: true)

					time_sms = "StoryTime: Great! Your child's birthdate is " + params[:Body][0,2] + "/" + params[:Body][2,2] + ". If not correct, reply REDO. If correct, enjoy your next age-appropriate story!"

					Helpers.text(mode, time_sms, time_sms, @user.phone)

	 		else #Wrong age rage

	 			@user.update(subscribed: false)

	 			#NOTE: Keep the real birthdate.
	 			Helpers.text(mode, TOO_YOUNG_SMS, TOO_YOUNG_SMS, @user.phone)

	 		end

	    else #not a valid format
	  		Helpers.text(mode, WRONG_BDAY_FORMAT, WRONG_BDAY_FORMAT, @user.phone)
		end 	

 	# Update TIME before (or after) third story
 	elsif @user.set_time == false && /(:|pm|am)/ =~ params[:Body]
 		
 		response = params[:Body]
 		arr = response.split

 		case arr.length
 		when 1

			if /\A[0-9]{1,2}[:][0-9]{2}[ap][m]\z/ =~ arr[0]
				
				@user.update(time: arr[0]) 
		        #They've set their own time, so don't ask again
		        @user.update(set_time: true)

				good_time = "StoryTime: Sounds good! Your new story time is #{@user.time}. Enjoy!"
				
					Helpers.text(mode, good_time, good_time, @user.phone)
			else
			
				Helpers.text(mode, BAD_TIME_SMS, BAD_TIME_SPRINT, @user.phone)
			end

		when 2
 				if /\A[0-9]{1,2}[:][0-9]{2}\z/ =~ arr[0] && /\A[ap][m]\z/ =~ arr[1]
 					
 					@user.update(time: arr[0] + arr[1])

 			        @user.update(set_time: true)

					good_time = "StoryTime: Sounds good! Your new story time is #{@user.time}. Enjoy!"
					
					Helpers.text(mode, good_time, good_time, @user.phone)

 				else
					
					Helpers.text(mode, BAD_TIME_SMS, BAD_TIME_SPRINT, @user.phone)

 				end
 		else 
		
			Helpers.text(mode, BAD_TIME_SMS, BAD_TIME_SPRINT, @user.phone)

		end

	#response matches nothing
	else

		Helpers.text(mode, NO_OPTION, NO_OPTION, @user.phone)

	end

end



