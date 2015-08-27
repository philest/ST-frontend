require 'sinatra'
require 'sinatra/activerecord'
require_relative './config/environments' #database configuration
require_relative './models/user' #add the user model
require 'twilio-ruby'
require 'sidekiq'
require 'sidetiq'
require 'redis'
require 'sidekiq/web'
require 'time'
require 'sinatra/r18n'

#set default locale to english
R18n::I18n.default = 'en'


#REDIS initialization
require_relative './config/initializers/redis'

require 'sidekiq/api'
require_relative './sprint'
require_relative './age'

	
require_relative './constants'

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

DEFAULT_TIME = Time.new(2015, 6, 21, 17, 30, 0) #Default Time: 17:30:00 (5:30PM), EST



module ApplicationHelper

	#This enrolls the phoneNumber for stories in that language
	#lang defaults to English.
	#wait_time is how long until the async call to send the message.
	def ApplicationHelper.enroll(params, user_phone, locale, *wait_time) 


		@user = User.find_by_phone(user_phone) #check if already registered.

		if @user == nil
			@user = User.create(phone: user_phone, locale: locale)
		else
			@user.update(sample: false)
			@user.update(subscribed: true) 
			@user.update(locale: locale)
		end

		if MODE == PRO #only relevant for production code
			#randomly assign to get two days a week or three days a week
			if (rand = Random.rand(9)) == 0
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


		@user.update(time: DEFAULT_TIME) #NEED THIS!
		# @user.update(child_age: 4)


		if MODE == PRO
			#TWILIO set up:
	   		account_sid = ENV['TW_ACCOUNT_SID']
	    	auth_token = ENV['TW_AUTH_TOKEN']
		  	@client = Twilio::REST::LookupsClient.new account_sid, auth_token

	    	# Lookup wireless carrier if it hasn't already been done in SAMPLE
	    	if @user.carrier == nil
			  	number = @client.phone_numbers.get(@user.phone, type: 'carrier')
			  	@user.update(carrier: number.carrier['name'])
			 end
	  	elsif MODE == TEST
	  		@user.update(carrier: params[:Carrier])
	  	end


	  	days = @user.days_per_week.to_s


	  	if locale != nil
			R18n.set(locale) 
		end

		#They texted to signup, so RESPOND.
		if params != nil && params[:Body] != nil
		  	if @user.carrier == Text::SPRINT
		  		Helpers.text_and_mms(R18n.t.start.sprint(days), R18n.t.first_mms.to_s, @user.phone)
		  	else
		  		Helpers.text_and_mms(R18n.t.start.normal(days), R18n.t.first_mms.to_s, @user.phone)
		  	end

		  	#update total message count #NOTE: This is done within NextMessageWorker for auto-enrolled.
		  	@user.update(total_messages: 1)


		#They were auto-enrolled, so SEND NEW.
		else
			wait_time = wait_time.shift

			if @user.carrier == Text::SPRINT
		  		NextMessageWorker.perform_in(wait_time.seconds, R18n.t.start.sprint(days), R18n.t.first_mms.to_s, @user.phone)
		  	else
		  		NextMessageWorker.perform_in(wait_time.seconds, R18n.t.start.normal(days), R18n.t.first_mms.to_s, @user.phone)
		  	end
		end


	end

	#manages entire registration workflow, keyword-selecting
	#defaults to English.
	def ApplicationHelper.workflow(params, locale)

		#strip whitespace (trailing and leading)
 		params[:Body] = params[:Body].strip
		params[:Body].gsub!(/[\.\,\!]/, '') #rid of periods, commas, exclamation points

		@user = User.find_by_phone(params[:From]) #check if already registered.

		#PRO, set locale for returning user 
		if locale != nil && @user != nil
			R18n.set(@user.locale) #set the locale for that user
		end

		#first reply: new user texts in STORY

		if params[:Body].casecmp(R18n.t.commands.story) == 0 && (@user == nil || @user.sample == true)

		ApplicationHelper.enroll(params, params[:From], locale)

		elsif (params[:Body].casecmp(R18n.t.commands.sample) == 0 || params[:Body].casecmp(R18n.t.commands.example) == 0)

			if @user == nil
				@user = User.create(sample: true, subscribed: false, phone: params[:From])
			end


			if params[:Body].casecmp(R18n.t.commands.sample) == 0 

				if MODE == PRO
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

			  	if @user.carrier == Text::SPRINT
					Helpers.text_and_mms(R18n.t.sample.sprint.to_s, R18n.t.first_mms.to_s, @user.phone)
				else
					Helpers.text_and_mms(R18n.t.sample.normal.to_s, R18n.t.first_mms.to_s, @user.phone)
				end

			else 
				Helpers.text_and_mms(R18n.t.example, R18n.t.first_mms, @user.phone) 
			end

		elsif @user == nil

			Helpers.text(R18n.t.error.no_signup_match, R18n.t.error.no_signup_match, params[:From])

		elsif @user.sample == true

			Helpers.text(R18n.t.sample.post, R18n.t.sample.post, @user.phone)

		
		#if auto-dropped (or if choose to drop mid-series), returning
		elsif (@user.next_index_in_series == 999 || @user.awaiting_choice == true) && (@user.subscribed == false && params[:Body].casecmp(R18n.t.commands.story) == 0)

			#REACTIVATE SUBSCRIPTION
				@user.update(subscribed: true)
				msg = R18n.t.stop.resubscribe.short + "\n\n" + R18n.t.choice.no_greet[@user.series_number] #longer message, give more newlines

				@user.update(next_index_in_series: 0)
				@user.update(awaiting_choice: true)

				Helpers.text(msg, msg, @user.phone)

		#if returning after manually stopping (not in mid - series)
		elsif @user.subscribed == false && params[:Body].casecmp(R18n.t.commands.story) == 0 

			#REACTIVATE SUBSCRIPTION
			@user.update(subscribed: true)
			Helpers.text(R18n.t.stop.resubscribe.long, R18n.t.stop.resubscribe.long, @user.phone)

		elsif params[:Body].casecmp(R18n.t.commands.help) == 0 #Text::HELP option
			
		  	#default 2 days a week
		  	if @user.days_per_week == nil
		  		@user.update(days_per_week: 2)
		  	end

		  	#find the day names
		  	case @user.days_per_week
		  	when 1
		  			dayNames = R18n.t.weekday.wed

		  	when 2, nil
		  		if @user.carrier == SPRINT
		  			dayNames =  R18n.t.weekday.sprint.tue + "/" + R18n.t.weekday.sprint.th
		  		else           
		  			dayNames = R18n.t.weekday.normal.tue + "/" + R18n.t.weekday.normal.th
		  		end
		  	when 3
		  		if @user.carrier == SPRINT
		  			dayNames = R18n.t.weekday.letters.M + "-" + R18n.t.weekday.letters.W + "-" + R18n.t.weekday.letters.F
		  		else           
		  			dayNames = R18n.t.weekday.mon + "/" + R18n.t.weekday.wed + "/" + R18n.t.weekday.fri
		  		end
		  	else
		  		puts "ERR: invalid days of week"
		  	end

			  	# Helpers.text(Text::HELP_SMS_1 + dayNames + Text::HELP_SMS_2, Text::HELP_SPRINT_1 + dayNames + Text::HELP_SPRINT_2, @user.phone)

		  	Helpers.text(R18n.t.help.normal(dayNames).to_s, R18n.t.help.sprint(dayNames).to_s, @user.phone)

		elsif params[:Body].casecmp(R18n.t.commands.break) == 0

			@user.update(on_break: true)
			@user.update(days_left_on_break: Text::BREAK_LENGTH)

			Helpers.text(R18n.t.break.start, R18n.t.break.start, @user.phone)


		elsif params[:Body].casecmp("STOP NOW") == 0 || params[:Body].casecmp(R18n.t.commands.stop) == 0#STOP option
			

			if MODE == PRO
			#SAVE QUITTERS
				REDIS.set(@user.phone+":quit", "true") 
				#update if the user quits
				#EX: REDIS.zadd("+15612125831:quit", true)  
			end

			#change subscription
			@user.update(subscribed: false)
			note = params[:From].to_s + "quit StoryTime."
			Helpers.new_text(note, note, "+15612125831")


		elsif params[:Body].casecmp(R18n.t.commands.text) == 0 #TEXT option		

			#change mms to sms
			@user.update(mms: false)

			Helpers.text(R18n.t.mms_update, R18n.t.mms_update, @user.phone)

		elsif params[:Body].casecmp("REDO") == 0 #texted STORY

			#no need to manually undo birthdate
			Helpers.text(Text::REDO_BIRTHDATE, Text::REDO_BIRTHDATE, @user.phone)

		#Responds with a letter when prompted to choose a series
		#Account for quotations
		elsif @user.awaiting_choice == true && /\A[']{0,1}["]{0,1}[a-zA-Z][']{0,1}["]{0,1}\z/ =~ params[:Body]			
			
			body = params[:Body]

			#has quotations => extract the juicy part
			if  !(/\A[a-zA-Z]\z/ =~ params[:Body])
				body = params[:Body][1,1]
			end

			body.downcase!

			#push back to zero incase this was changed to 999 to denote one 'day' after
	        @user.update(next_index_in_series: 0)

			#check if the choice is valid
			if MessageSeries.codeIsInHash( body + @user.series_number.to_s)
		 			
				#update the series choice
				@user.update(series_choice: body)
				@user.update(awaiting_choice: false)


			    messageSeriesHash = MessageSeries.getMessageSeriesHash
			    story = messageSeriesHash[@user.series_choice + @user.series_number.to_s][0]


				if @user.mms == true
					
					#incase of just one photo, this updates user-info.
					NextMessageWorker.perform_in(17.seconds, story.getSMS, story.getMmsArr[1..-1], @user.phone)

					if story.getMmsArr.length > 1 #don't need to send stack if it's a one-pager.
						Helpers.mms(story.getMmsArr[0], @user.phone)
					else
						Helpers.text_and_mms(story.getSMS, story.getMmsArr[0], @user.phone)
				    end

				else # just SMS
			        NextMessageWorker.updateUser(@user.phone, story.getPoemSMS)
			        Helpers.text(story.getPoemSMS, story.getPoemSMS, @user.phone)      
				end

		 	else	 			
				Helpers.text(R18n.t.error.bad_choice, R18n.t.error.bad_choice, @user.phone)
		 	end				

	    # second reply: update child's birthdate
	    elsif @user.set_birthdate == true && /[0-9]{4}/ =~ params[:Body]
	   		
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

						time_sms = "StoryTime: Great! Your child's birthdate is " + params[:Body][0,2] + "/" + params[:Body][2,2] + ". If not correct, reply REDO. If correct, enjoy your next age-appropriate story!"

						Helpers.text(time_sms, time_sms, @user.phone)

		 		else #Wrong age rage

		 			@user.update(subscribed: false)

		 			#NOTE: Keep the real birthdate.
		 			Helpers.text(Text::TOO_YOUNG_SMS, Text::TOO_YOUNG_SMS, @user.phone)

		 		end

		    else #not a valid format
		  		Helpers.text(Text::WRONG_BDAY_FORMAT, Text::WRONG_BDAY_FORMAT, @user.phone)
			end 	

	 	# Update TIME before (or after) third story
	 	elsif @user.set_time == true && /(:|pm|am)/ =~ params[:Body]
	 		
	 		response = params[:Body]
	 		arr = response.split

	 		case arr.length
	 		when 1

				if /\A[0-9]{1,2}[:][0-9]{2}[ap][m]\z/ =~ arr[0]
					
					@user.update(time: arr[0]) 

					good_time = "StoryTime: Sounds good! Your new story time is #{@user.time}. Enjoy!"

						Helpers.text(good_time, good_time, @user.phone)
				else
				
					Helpers.text(Text::BAD_TIME_SMS, Text::BAD_TIME_SPRINT, @user.phone)
				end

			when 2
	 				if /\A[0-9]{1,2}[:][0-9]{2}\z/ =~ arr[0] && /\A[ap][m]\z/ =~ arr[1]
	 					
	 					@user.update(time: arr[0] + arr[1])

	 					#They've set their own time, so don't ask again


						good_time = "StoryTime: Sounds good! Your new story time is #{@user.time}. Enjoy!"
						
						Helpers.text(good_time, good_time, @user.phone)

	 				else
						
						Helpers.text(Text::BAD_TIME_SMS, Text::BAD_TIME_SPRINT, @user.phone)

	 				end
	 		else 
			
				Helpers.text(Text::BAD_TIME_SMS, Text::BAD_TIME_SPRINT, @user.phone)

			end

		#response matches nothing
		else

			Helpers.text(R18n.t.error.no_option, R18n.t.error.no_option, @user.phone)

		end#signup flow

	end

end



configure :production do
  require 'newrelic_rpm'
end



MODE = ENV['RACK_ENV']

PRO = "production"
TEST = "test"



include Text


helpers ApplicationHelper



get '/worker' do
	SomeWorker.perform_async #begin sidetiq recurrring background tasks
	redirect to('/')
end

get '/' do
	erb :main
end

get '/mp3' do
	send_file File.join(settings.public_folder, 'storytime_message.mp3')
end

get '/failed' do
	Helpers.smsRespondHelper("StoryTime: Hi! We're updating StoryTime now and are offline, but be sure to check back in the next day!")
end

get '/called' do
  Twilio::TwiML::Response.new do |r|
    r.Play "http://www.joinstorytime.com/mp3"
  end.text
end


# register an incoming SMS
get '/sms' do

	if params[:locale] == nil
		locale = 'en'
	else
		locale = params[:locale]
	end

	ApplicationHelper.workflow(params, locale)
end

# mock entrypoint for testing
get '/test/:From/:Body/:Carrier' do

	if params[:locale] == nil
		locale = 'en'
	else
		locale = params[:locale]
	end

	ApplicationHelper.workflow(params, locale)
end







