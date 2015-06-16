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
require_relative './messageSeries'
require_relative './workers/some_worker'
require_relative './workers/first_text_worker'
require_relative './workers/choice_worker'


# require 'pry'

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

	#first reply: new user, add her
	if @user == nil 

		@user = User.create(phone: params[:From])

		#randomly assign to get two days a week or three days a week
		if (rand = Random.rand(9)) == 0
			@user.update(days_per_week: 3)
		elsif rand < 5
			@user.update(days_per_week: 1)
		else
			@user.update(days_per_week: 2)
		end

		#update subscription
		@user.update(subscribed: true) #Subscription complete! (B/C defaults)
		#backup for defaults
		@user.update(time: "5:00pm", child_age: 4)


		#TWILIO set up:
   		account_sid = ENV['TW_ACCOUNT_SID']
    	auth_token = ENV['TW_AUTH_TOKEN']
	  	@client = Twilio::REST::LookupsClient.new account_sid, auth_token

    	# Lookup wireless carrier
	  	number = @client.phone_numbers.get(@user.phone, type: 'carrier')
	  	@user.update(carrier: number.carrier['name'])


	  	days = @user.days_per_week.to_s

	  	
	  	FirstTextWorker.perform_in(18.seconds, @user.phone)

	  	text(START_SMS_1 + days + START_SMS_2, START_SPRINT_1 + days + START_SPRINT_2)	


	elsif @user.subscribed == false && params[:Body].casecmp("STORY") == 0 #if returning

			#REACTIVATE SUBSCRIPTION
			@user.update(subscribed: true)
			@user.update(next_index_in_series: nil)

			text(RESUBSCRIBE, RESUBSCRIBE)

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

	  	text(HELP_SMS_1 + dayNames + HELP_SMS_2, HELP_SPRINT_1 + dayNames + HELP_SPRINT_2)


	elsif params[:Body].casecmp(STOP) == 0 #STOP option
		

		#SAVE QUITTERS
		REDIS.set(@user.phone+":quit", "true") 
			#update if the user quits
			#EX: REDIS.zadd("+15612125831:quit", true)  

		#change subscription
		@user.update(subscribed: false)

		text(STOPSMS, STOPSMS)

	elsif params[:Body].casecmp(TEXT) == 0 #TEXT option
		

		#change mms to sms
		@user.update(mms: false)

		text(MMS_UPDATE, MMS_UPDATE)

	elsif params[:Body].casecmp("REDO") == 0 #texted STORY

		#no need to manually undo birthdate
		text(REDO_BIRTHDATE, REDO_BIRTHDATE)

	#Responds with a letter when prompted to choose a series
	#Account for quotations
	elsif @user.awaiting_choice == true && /\A[']{0,1}["]{0,1}[a-zA-Z][']{0,1}["]{0,1}\z/ =~ params[:Body]			
		
		body = params[:Body]

		#has quotations => extract the juicy part
		if  !(/\A[a-zA-Z]\z/ =~ params[:Body])
			body = params[:Body][1,1]
		end

		#push back to zero incase this was changed to -1 to denote one 'day' after
        @user.update(next_index_in_series: 0)

		#check if the choice is valid
		if MessageSeries.codeIsInHash( body + @user.series_number)
	 			
			#update the series choice
			@user.update(series_choice: body)
			    @user.update(awaiting_choice: false)

			#send the choice text
			ChoiceWorker.perform_in(18.seconds, @user.phone)

			text(GOOD_CHOICE, GOOD_CHOICE)
	 	else	 			
			text(BAD_CHOICE, BAD_CHOICE)
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

					time_sms = "StoryTime: Great! Your child's birthdate is " + params[:Body][0,2] + "/" + params[:Body][2,2] + ". If not correct, reply STORY. If correct, enjoy your next age-appropriate story!"

					text(time_sms, time_sms)

	 		else #Wrong age rage

	 			@user.update(subscribed: false)

	 			#NOTE: Keep the real birthdate.
	 			text(TOO_YOUNG_SMS, TOO_YOUNG_SMS)

	 		end

	    else #not a valid format
	  		text(WRONG_BDAY_FORMAT, WRONG_BDAY_FORMAT)
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
				
				text(good_time, good_time)
			else
			
				text(BAD_TIME_SMS, BAD_TIME_SPRINT)
			end

		when 2
 				if /\A[0-9]{1,2}[:][0-9]{2}\z/ =~ arr[0] && /\A[ap][m]\z/ =~ arr[1]
 					
 					@user.update(time: arr[0] + arr[1])

					good_time = "StoryTime: Sounds good! Your new story time is #{@user.time}. Enjoy!"
					
					text(good_time, good_time)

 				else
					
					text(BAD_TIME_SMS, BAD_TIME_SPRINT)

 				end
 		else 
		
			text(BAD_TIME_SMS, BAD_TIME_SPRINT)

		end

	#response matches nothing
	else

		text(NO_OPTION, NO_OPTION)

	end

end



helpers do

	def text(normalSMS, sprintSMS)
	
		#if sprint
		if @user.carrier == SPRINT

			msg = sprintSMS 

			puts "Sent message to #{@user.phone}: " + "\"" + msg[0,18] + "...\""


			twiml = Twilio::TwiML::Response.new do |r|
	   			r.Message sprintSMS #SEND SPRINT MSG
	    	end
	    	twiml.text

		else #not Sprint

			msg = normalSMS 

			puts "Sent message to #{@user.phone}: " + "\"" + msg[0,18] + "...\""

			twiml = Twilio::TwiML::Response.new do |r|
	   			r.Message normalSMS	#SEND NORMAL
	    	end
	    	twiml.text
		end 


	end  	

 	def test_text(normalSMS, sprintSMS)

	 	#if sprint
		if @user.carrier == SPRINT

			@@twiml = sprintSMS

		else #not Sprint
			@@twiml = normalSMS
		end 

	end


end











#THIS IS SIMPLY FOR TESTING! UPDATED JUNE 12. 

get '/test/:From/:Body/:Carrier' do



	#check if new user
	#returns nil if not found
	@user = User.find_by_phone(params[:From]) 

	if @user != nil #if user exists
		@user.update(carrier: params[:Carrier]) 
	end

	if @user == nil
		#2 days per week
		@user = User.create(phone: params[:From], days_per_week: 2, carrier: params[:Carrier] )

		#update subscription
		@user.update(subscribed: true) #Subscription complete! (B/C defaults)
		#backup for defaults
		@user.update(time: "5:00pm", child_age: 4)

	  	days = @user.days_per_week.to_s
	  	
	  	# FirstTextWorker.perform_in(18.seconds, @user.phone)

	  	test_text(START_SMS_1 + days + START_SMS_2, START_SPRINT_1 + days + START_SPRINT_2)	


	elsif @user.subscribed == false && params[:Body].casecmp("STORY") == 0 #if returning

			#REACTIVATE SUBSCRIPTION
			@user.update(subscribed: true)
			@user.update(next_index_in_series: nil)

			test_text(RESUBSCRIBE, RESUBSCRIBE)

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

	  	test_text(HELP_SMS_1 + dayNames + HELP_SMS_2, HELP_SPRINT_1 + dayNames + HELP_SPRINT_2)

	elsif params[:Body].casecmp(STOP) == 0 #STOP option
		

		#SAVE QUITTERS
		# REDIS.set(@user.phone+":quit", "true") 
			#update if the user quits
			#EX: REDIS.zadd("+15612125831:quit", true)  

		#change subscription
		@user.update(subscribed: false)

		test_text(STOPSMS, STOPSMS)

	elsif params[:Body].casecmp(TEXT) == 0 #TEXT option
		
		#change mms to sms
		@user.update(mms: false)

		test_text(MMS_UPDATE, MMS_UPDATE)

	elsif params[:Body].casecmp("REDO") == 0 #texted STORY

		#no need to manually undo birthdate
		test_text(REDO_BIRTHDATE, REDO_BIRTHDATE)

	#Responds with a letter when prompted to choose a series
	#Account for quotations
	elsif @user.awaiting_choice == true && /\A[']{0,1}["]{0,1}[a-zA-Z][']{0,1}["]{0,1}\z/ =~ params[:Body]			
		
		body = params[:Body]

		#has quotations => extract the juicy part
		if  !(/\A[a-zA-Z]\z/ =~ params[:Body])
			body = params[:Body][1,1]
		end

		#push back to zero incase this was changed to -1 to denote one 'day' after
        @user.update(next_index_in_series: 0)

		#check if the choice is valid
		if MessageSeries.codeIsInHash( body + @user.series_number)
	 			
			#update the series choice
			@user.update(series_choice: body)
			 @user.update(awaiting_choice: false)

			#send the choice text
			ChoiceWorker.perform_in(18.seconds, @user.phone)

			test_text(GOOD_CHOICE, GOOD_CHOICE)
	 	else	 			
			test_text(BAD_CHOICE, BAD_CHOICE)
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

					time_sms = "StoryTime: Great! Your child's birthdate is " + params[:Body][0,2] + "/" + params[:Body][2,2] + ". If not correct, reply STORY. If correct, enjoy your next age-appropriate story!"

					test_text(time_sms, time_sms)

	 		else #Wrong age rage

	 			@user.update(subscribed: false)

	 			#NOTE: Keep the real birthdate.
	 			test_text(TOO_YOUNG_SMS, TOO_YOUNG_SMS)

	 		end

	    else #not a valid format
	  		test_text(WRONG_BDAY_FORMAT, WRONG_BDAY_FORMAT)
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
				
				test_text(good_time, good_time)
			else
			
				test_text(BAD_TIME_SMS, BAD_TIME_SPRINT)
			end

		when 2
 				if /\A[0-9]{1,2}[:][0-9]{2}\z/ =~ arr[0] && /\A[ap][m]\z/ =~ arr[1]
 					
 					@user.update(time: arr[0] + arr[1])

					good_time = "StoryTime: Sounds good! Your new story time is #{@user.time}. Enjoy!"
					
					test_text(good_time, good_time)

 				else
					
					test_text(BAD_TIME_SMS, BAD_TIME_SPRINT)

 				end
 		else 
		
			test_text(BAD_TIME_SMS, BAD_TIME_SPRINT)

		end

	#response matches nothing
	else

		test_text(NO_OPTION, NO_OPTION)

	end#end options

end#end TEST get
