require 'sinatra'
require 'sinatra/activerecord'
require_relative './config/environments' #database configuration
require_relative './models/user' #add the user model
require 'twilio-ruby'
require 'sidekiq'
require 'sidetiq'
require 'redis'

require 'time'

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


configure :production do
  require 'newrelic_rpm'
end

DEFAULT_TIME = Time.new(2015, 6, 21, 17, 30, 0) #Default Time: 17:30:00 (5:30PM), EST


MODE = ENV['RACK_ENV']

PRO = "production"
TEST = "test"



include Text


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

get '/three' do 

	arr = ["http://i.imgur.com/gNPKPSs.jpg", "http://i.imgur.com/SRDF3II.jpg", "http://i.imgur.com/tNSDIZf.jpg"]
	twiml = Twilio::TwiML::Response.new do |r|
	    r.Message do |m|
	      m.Media arr[0]
	      m.Media arr[1]
		  m.Media arr[2]
	    end
	  end
	  twiml.text
end

get '/three_send' do 
		arr = ["http://i.imgur.com/gNPKPSs.jpg", "http://i.imgur.com/SRDF3II.jpg", "http://i.imgur.com/tNSDIZf.jpg"]
   		
		    account_sid = ENV['TW_ACCOUNT_SID']
		    auth_token = ENV['TW_AUTH_TOKEN']
			@client = Twilio::REST::Client.new account_sid, auth_token
			
			pe = "+15612125831"
			jz = "+15619008225"

          message = @client.account.messages.create(
            :media_url => arr,
            :to => jz,     # Replace with your phone number
            :from => "+12032023505")   # Replace with your Twilio number
end



# register an incoming SMS
get '/sms' do
	workflow
end


# mock entrypoint for testing
get '/test/:From/:Body/:Carrier' do
	workflow
end


helpers do 

	def workflow 


		#check if new user
		#returns nil if not found
		@user = User.find_by_phone(params[:From])
		
		#first reply: new user texts in STORY
		if params[:Body].casecmp("STORY") == 0 && (@user == nil || @user.sample == true)

			if @user == nil
				@user = User.create(phone: params[:From])
			else
				@user.update(sample: false)
				@user.update(subscribed: true) 
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

				require 'pry'
				binding.pry


				@user.update(time: DEFAULT_TIME) #NEED THIS!
				# @user.update(child_age: 4)


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


			  	days = @user.days_per_week.to_s

				NextMessageWorker.perform_in(13.seconds, Text::FIRST_SMS, Text::FIRST_MMS, @user.phone)

			  	Helpers.text(Text::START_SMS_1 + days + Text::START_SMS_2, Text::START_SPRINT_1 + days + Text::START_SPRINT_2, @user.phone)	


		elsif (params[:Body].casecmp("SAMPLE") == 0 || params[:Body].casecmp("EXAMPLE") == 0)

			if @user == nil
				@user = User.create(sample: true, subscribed: false, phone: params[:From])
			end

			if params[:Body].casecmp("SAMPLE") == 0 
				NextMessageWorker.perform_in(17.seconds, Text::SAMPLE_SMS, Text::THE_FINAL_MMS, @user.phone)
			else #EXAMPLE
				NextMessageWorker.perform_in(17.seconds, Text::EXAMPLE_SMS, Text::THE_FINAL_MMS, @user.phone)
			end

			Helpers.mms(Text::FIRST_MMS[0], @user.phone) 


		elsif @user == nil

			Helpers.text(Text::Text::NO_SIGNUP_MATCH, Text::Text::NO_SIGNUP_MATCH, params[:From])

		elsif @user.sample == true

			Helpers.text(Text::POST_SAMPLE, Text::POST_SAMPLE, @user.phone)
		
		#if auto-dropped (or if choose to drop mid-series), returning
		elsif (@user.next_index_in_series == 999 || @user.awaiting_choice == true) && (@user.subscribed == false && params[:Body].casecmp("STORY") == 0)

			#REACTIVATE SUBSCRIPTION
				@user.update(subscribed: true)
				msg = Text::RESUBSCRIBE_SHORT + "\n\n" + SomeWorker::NO_GREET_CHOICES[@user.series_number] #longer message, give more newlines

				@user.update(next_index_in_series: 0)
				@user.update(awaiting_choice: true)

				Helpers.text(msg, msg, @user.phone)

		#if returning after manually stopping (not in mid - series)
		elsif @user.subscribed == false && params[:Body].casecmp("STORY") == 0 

			#REACTIVATE SUBSCRIPTION
			@user.update(subscribed: true)
			Helpers.text(Text::RESUBSCRIBE_LONG, Text::RESUBSCRIBE_LONG, @user.phone)

		elsif params[:Body].casecmp(Text::HELP) == 0 #Text::HELP option
			
		  	#default 2 days a week
		  	if @user.days_per_week == nil
		  		@user.update(days_per_week: 2)
		  	end

		  	#find the day names
		  	case @user.days_per_week
		  	when 1
		  			dayNames = "Wed"

		  	when 2, nil
		  		if @user.carrier == SPRINT
		  			dayNames = "Tue/Th"
		  		else           
		  			dayNames = "Tues & Thurs"
		  		end
		  	when 3
		  		if @user.carrier == SPRINT
		  			dayNames = "M-W-F"
		  		else           
		  			dayNames = "Mon/Wed/Fri"
		  		end
		  	else
		  		puts "ERR: invalid days of week"
		  	end

		  	Helpers.text(Text::HELP_SMS_1 + dayNames + Text::HELP_SMS_2, Text::HELP_SPRINT_1 + dayNames + Text::HELP_SPRINT_2, @user.phone)


		elsif params[:Body].casecmp("STOP NOW") == 0 #STOP option
			

			if MODE == PRO
			#SAVE QUITTERS
				REDIS.set(@user.phone+":quit", "true") 
				#update if the user quits
				#EX: REDIS.zadd("+15612125831:quit", true)  
			end

			#change subscription
			@user.update(subscribed: false)
			Helpers.text(Text::STOPSMS, Text::STOPSMS, @user.phone)

		elsif params[:Body].casecmp(Text::TEXT) == 0 #TEXT option		

			#change mms to sms
			@user.update(mms: false)

			Helpers.text(Text::MMS_UPDATE, Text::MMS_UPDATE, @user.phone)

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
					NextMessageWorker.perform_in(17.seconds, story.getSMS, story.getMmsArr[1..-1], @user.phone)

					Helpers.mms(story.getMmsArr[0], @user.phone)
				else
			        Helpers.text(story.getPoemSMS, story.getPoemSMS, @user.phone)      
				end

		 	else	 			
				Helpers.text(Text::BAD_CHOICE, Text::BAD_CHOICE, @user.phone)
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

			Helpers.text(Text::NO_OPTION, Text::NO_OPTION, @user.phone)

		end#signup flow

	end#workflow method

end#helpers


