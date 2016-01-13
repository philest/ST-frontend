#  helpers/twilio_helper.rb                   Phil Esterman     
# 
#  TwilioHelper for Twilio messaging.  
#  --------------------------------------------------------


require 'sinatra/r18n'
require 'twilio-ruby'
require_relative '../workers/new_text_worker'

#set Twilio credentials:
account_sid = ENV['TW_ACCOUNT_SID']
auth_token = ENV['TW_AUTH_TOKEN']

@client = Twilio::REST::Client.new account_sid, auth_token


class TwilioHelper

SPRINT = "Sprint Spectrum, L.P."

SMS_HELPER = "SMS_HELPER"
PRO ||= "production"
TEST ||="test"
TEST_CRED = "test_cred"

# @@my_twilio_number = "+17377778679"


LAST = "last"
NORMAL = "normal"

NO_WAIT = "no wait"

@@mode = ENV['RACK_ENV']




SMS_WAIT = 12

LAST_WAIT = 1

MMS_WAIT = 20

MMS = "MMS"
SMS = "SMS"

#testing goods
	def self.initialize_testing_vars
		@@twiml_sms = Array.new
	  	@@twiml_mms = Array.new
	  	@@twiml = ""

	  	@@test_sleep = false
	end

	def self.getSimpleSMS
		return @@twiml
	end

	def self.getSMSarr
		return @@twiml_sms
	end

	def self.getMMSarr
		return @@twiml_mms
	end

	def self.addToSMSarr(elt)
		return @@twml_sms.push elt
	end

	def self.addToMMSarr(elt)
		return @@twml_mms.push elt
	end

	#turns on test_sleep so sleeps while running tests
	def self.testSleep
		@@test_sleep = true
	end

	def self.testSleepOff
		@@test_sleep = false
	end

	def self.getTestSleep
		return @@test_sleep
	end


	def self.testCred	
		#set up test credentials
	    account_sid = ENV['TEST_TW_ACCOUNT_SID']
	    auth_token = ENV['TEST_TW_AUTH_TOKEN']

	   	@client = Twilio::REST::Client.new account_sid, auth_token

   		@@my_twilio_number = "+15005550006"
   		@@mode = TEST_CRED
	end

	def self.testCredOff
		@@mode = ENV['RACK_ENV']
	end


	if ENV['RACK_ENV'] == "production"
		@@my_twilio_number = "+12032023505"	   		

	elsif ENV['RACK_ENV'] == 'test'		#test credentials for integration from SMS.
		TwilioHelper.initialize_testing_vars
	end
 	
	# #TwilioHelper that simply twiml REST API
	# if ENV['RACK_ENV'] == "production"
	# 		#set TWILIO credentials:
		    # account_sid = ENV['TW_ACCOUNT_SID']
		    # auth_token = ENV['TW_AUTH_TOKEN']

	   		# @client = Twilio::REST::Client.new account_sid, auth_token
			
	# 		@@my_twilio_number = "+12032023505"	   		
	# end





   	def self.getSleep(order, type)
		if @@mode == TEST || @@mode == TEST_CRED
   			if @@test_sleep && order == NORMAL

   				if type == SMS
   					return SMS_WAIT
   				elsif type == MMS
   					return MMS_WAIT
   				end

   			elsif @@test_sleep && order == LAST
   				return LAST_WAIT
   			else
   				return 0 #nosleep if @@test_sleep is false
   			end

		elsif @@mode == PRO
   			
   			if order == NORMAL
   				if type == SMS
   					return SMS_WAIT
   				elsif type == MMS
   					return MMS_WAIT
   				end

   			elsif order == LAST
   				return LAST_WAIT
   			
   			elsif order == NO_WAIT
   				return 0
   			end
   		else 
   			puts "ERROR: Invalid ENV mode!: #{@@mode}"
		end
	end


   	#BIG KAHUNA
   	#takes care of sleeping (order-specific), and handles testing and normal
	def self.smsRespond(body, order)

   		if @@mode == TEST
   			@@twiml = body
   			@@twiml_sms.push body

   		elsif @@mode == PRO || @@mode == TEST_CRED
   			
   			TwilioHelper.smsRespondHelper(body)
   		end

	end

	def self.mmsRespond(mms_url)

		if @@mode == TEST || @@mode == TEST_CRED
			@@twiml_mms.push mms_url
		elsif @@mode == PRO
			TwilioHelper.mmsRespondHelper(mms_url)
		end

   	end

   	def self.fullRespond(body, mms_url, order)


   		if mms_url.class == Array
   			mms_url = mms_url.shift
   		end

   		if @@mode == TEST || @@mode == TEST_CRED
			@@twiml_mms.push mms_url
			@@twiml_sms.push body
		elsif @@mode == PRO
			TwilioHelper.fullRespondHelper(body, mms_url)
		end

	end



   	def self.smsSend(body, user_phone)
		if @@mode == TEST || @@mode == TEST_CRED
			@@twiml = body
			@@twiml_sms.push body

			#turn on testcred
			TwilioHelper.testCred
		end
			#for Test_Cred: simulate actual REST api
			TwilioHelper.smsSendHelper(body, user_phone)
		
   	end


   	def self.mmsSend(mms_url, user_phone)
		if @@mode == TEST || @@mode == TEST_CRED
			@@twiml_mms.push mms_url
			puts "Sent #{mms_url[-10..-5]}"
		elsif @@mode == PRO
			TwilioHelper.mmsSendHelper(mms_url, user_phone)
		end
   	end

   	def self.fullSend(body, mms_url, user_phone, order)

		#account for mms_url in arrays
    	if mms_url.class == Array
    		mms_url = mms_url[0]
    	end
		
		TwilioHelper.fullSendHelper(body, mms_url, user_phone)
   	end




   	##sending helpers!

	def self.smsRespondHelper(body)
			twiml = Twilio::TwiML::Response.new do |r|
		   		r.Message body #SEND SPRINT MSG
		   	end
		    twiml.text
	end

	def self.mmsRespondHelper(mms_url)
		  twiml = Twilio::TwiML::Response.new do |r|
		    r.Message do |m|
		      m.Media mms_url
		    end
		  end
		  twiml.text
	end

	def self.fullRespondHelper(body, mms_url)

		  twiml = Twilio::TwiML::Response.new do |r|
		    r.Message do |m|
		      m.Media mms_url
		      m.Body body
		    end
		  end
		  twiml.text
	end





	def self.smsSendHelper(body, user_phone)

   		if @@mode == PRO
		    account_sid = ENV['TW_ACCOUNT_SID']
		    auth_token = ENV['TW_AUTH_TOKEN']
			@client = Twilio::REST::Client.new account_sid, auth_token
		end

          message = @client.account.messages.create(
            :body => body,
            :to => user_phone,     # Replace with your phone number
            :from => @@my_twilio_number)   # Replace with your Twilio number

        if @@mode == TEST_CRED 
        	puts "TC: Sent sms to #{user_phone}: #{body[10, 18]}" 
       	else
    		puts "Sent sms to #{user_phone}: #{body[10, 18]}"
    	end 

		  #turn off testCred
	      TwilioHelper.testCredOff
    end

    def self.mmsSendHelper(mms_url, user_phone)
   		
   		if @@mode == PRO
		    account_sid = ENV['TW_ACCOUNT_SID']
		    auth_token = ENV['TW_AUTH_TOKEN']
			@client = Twilio::REST::Client.new account_sid, auth_token
		end

          message = @client.account.messages.create(
            :media_url => mms_url,
            :to => user_phone,     # Replace with your phone number
            :from => @@my_twilio_number)   # Replace with your Twilio number

    	puts "Sent mms to #{user_phone}: #{mms_url[-10..-5]}"
    end

    def self.fullSendHelper(body, mms_url, user_phone)
  
   		if @@mode == PRO
		    account_sid = ENV['TW_ACCOUNT_SID']
		    auth_token = ENV['TW_AUTH_TOKEN']
			@client = Twilio::REST::Client.new account_sid, auth_token
		end
          
		#get user
		@user = User.find_by_phone(user_phone)

		#chop up if a long message to a sprint user.
		if body.length >= 160 && @user.carrier == Text::SPRINT 
		    
			sprint_arr = Sprint.chop(body)

			if @@mode == TEST || @@mode == TEST_CRED
			
				@@twiml_mms.push mms_url
				@@twiml_sms.push sprint_arr.shift #add first part

			else

				#send mms with first part of sms series
				message = @client.account.messages.create(
	            :media_url => mms_url,
	            :body => sprint_arr.shift,
	            :to => user_phone,    
	            :from => @@my_twilio_number)

			end 

			puts "Sent #{mms_url[-10..-5]} and sms part 1"

			#send the rest of sms series
            NewTextWorker.perform_in(MMS_WAIT.seconds, sprint_arr, NewTextWorker::NOT_STORY, user_phone)

        else #not long-sprint

			if @@mode == TEST || @@mode == TEST_CRED
				@@twiml_mms.push mms_url
				@@twiml_sms.push body
				puts "Sent #{mms_url[-10..-5]}, #{body}"

	        else
	           message = @client.account.messages.create(
	            :body => body,
	            :media_url => mms_url,
	            :to => user_phone,     # Replace with your phone number
	            :from => @@my_twilio_number)   # Replace with your Twilio number
			end

		end

        puts "Sent mms to #{user_phone}: #{mms_url[-10..-5]}"
    	puts "along with sms: #{body[10, 18]}" 

    end






	#RESPONSE SMS texting

	#ONLY A RESPONSE

	def self.text_and_mms(body, mms_url, user_phone)

		@user = User.find_by(phone: user_phone)

		if @user == nil
    		puts "Sent full to new user"
    	else
			puts "Sent full to #{@user.phone}}" 
  		end

    	TwilioHelper.fullRespond(body, mms_url, LAST)
    end



	def self.mms(mms, user_phone)
    	 
		
		if (user = User.find_by(phone: user_phone)) == nil
    		puts "Sent mms to new user"
    	else
    		puts "Sent to #{user.phone}: #{mms[-10..-5]}" 
  		end


    	TwilioHelper.mmsRespond(mms)

	end


	def self.text(normalSMS, sprintSMS, user_phone)
	
 		@user = User.find_by(phone: user_phone)

		#if sprint
		if (@user == nil || @user.carrier == SPRINT) &&
				sprintSMS.length > 160

			sprintArr = Sprint.chop(sprintSMS)
			msg = sprintArr.shift # pop off first element
								  # and send as immediate reply.

			# Send all but first SMS asynchronously. 
			NewTextWorker.perform_in(14.seconds,
								     sprintArr,
								     NewTextWorker::NOT_STORY,
								     @user.phone)

		elsif @user == nil || @user.carrier == SPRINT
			msg = sprintSMS 
		else
			msg = normalSMS
		end

		if (@@mode == TEST || @@mode == TEST_CRED) && ((@user == nil || @user.carrier == SPRINT) && sprintSMS.length > 160)
			NewTextWorker.drain
		end

		if @user == nil
    		puts "Sent full to new user"
    	else
			puts "Sent sms to #{@user.phone}: " + "\"" + msg[10,18] + "...\""
  		end
		
		TwilioHelper.smsRespond(msg, LAST)

	end  





	#RESPONSE Sprint SMS LONG

	#helper method to deliver sprint texts
	def self.new_sprint_long_sms(long_sms, user_phone)

		@user = User.find_by(phone: user_phone)

		#find if it's first story or not
		if @user.total_messages < 1
			type = NewTextWorker::STORY
		else
			type = NewTextWorker::NOT_STORY
		end

		NewTextWorker.perform_async(long_sms, type, user_phone)

	end







	def self.new_mms(sms, mms_array, user_phone)

		@user = User.find_by(phone: user_phone)

		##account for single mms as string
		if mms_array.class == String
			mms_array = [mms_array]
		end


		#if long sprint mms + sms, send all images, then texts one-by-one
		if @user != nil && (@user.carrier == SPRINT && sms.length > 160)

			mms_array.each_with_index do |mms_url, index|
					
					TwilioHelper.mmsSend(mms_url, user_phone)
		     	 	 #for all, because text follows
			end

			TwilioHelper.new_sprint_long_sms(sms, user_phone)

		else

			mms_array.each_with_index do |mms, index|

				if index + 1 == mms_array.length #last image comes w/ SMS
				
					TwilioHelper.fullSend(sms, mms, user_phone, LAST)

				else

					TwilioHelper.mmsSend(mms, user_phone)

				end

			end

		end

	end





	def self.new_sms_sandwich_mms(first_sms, last_sms, mms_array, user_phone)

		@user = User.find_by(phone: user_phone)


		#if long sprint mms + sms, send all images, then texts one-by-one
		if @user != nil && (@user.carrier == SPRINT && sms.length > 160)

			TwilioHelper.new_sprint_long_sms(sms, user_phone)

			mms_array.each_with_index do |mms_url, index|

				if index + 1 != mms_array.length
				TwilioHelper.mmsSend(mms_url, user_phone)
		    	else
				TwilioHelper.mmsSend(mms_url, user_phone)
				end

			end

		else
			#SMS first!

			TwilioHelper.smsSend(first_sms, user_phone)

			TwilioHelper.mms_array.each_with_index do |mms_url, index|


				if index + 1 == mms_array.length #send sms with mms on last story

					TwilioHelper.fullSend(last_sms, mms_url, user_phone, LAST)

				else

					TwilioHelper.mmsSend(mms_url, user_phone)

				end


			end

		end

	end














	def self.new_sms_first_mms(sms, mms_array, user_phone)

		@user = User.find_by(phone: user_phone)

		#if long sprint mms + sms, send all images, then texts one-by-one
		if @user != nil && (@user.carrier == SPRINT && sms.length > 160)

			TwilioHelper.new_sprint_long_sms(sms, user_phone)

			sleep SMS_WAIT

			mms_array.each_with_index do |mms, index|

				TwilioHelper.mmsSend(mms, user_phone)

				if index + 1 != mms_array.length

					TwilioHelper.mmsSend(mms, user_phone)

		    	else
					TwilioHelper.mmsSend(mms, user_phone)
				end

			end

		else
			#SMS first!

			TwilioHelper.smsSend(sms, user_phone)

			mms_array.each_with_index do |mms, index|
			
				if index + 1 != mms_array.length
					TwilioHelper.mmsSend(mms, user_phone)
		    	else
					TwilioHelper.mmsSend(mms, user_phone)
				end

			end

		end

	end







	def self.new_just_mms(mms_array, user_phone)

		#handle just a single, String mms_url
		if mms_array.class == String
			mms_array = [mms_array]
		end


		@user = User.find_by(phone: user_phone)

			mms_array.each_with_index do |mms, index|


				if index + 1 != mms_array.length
					TwilioHelper.mmsSend(mms, user_phone)
		    	else
					TwilioHelper.mmsSend(mms, user_phone)
				end

			end
	end



	def self.new_just_mms_no_wait(mms_array, user_phone)

		#handle just a single, String mms_url
		if mms_array.class == String
			mms_array = [mms_array]
		end


		@user = User.find_by(phone: user_phone)

			mms_array.each_with_index do |mms, index|


				if index + 1 != mms_array.length
					TwilioHelper.mmsSend(mms, user_phone)
		    	else
					TwilioHelper.mmsSend(mms, user_phone)
				end

			end
	end





	#send a NEW, unprompted text-- NOT a response
	def self.new_text(normalSMS, sprintSMS, user_phone)
		
		@user = User.find_by(phone: user_phone)

		#if sprint
		if (@user == nil || @user.carrier == SPRINT) && sprintSMS.length > 160

			TwilioHelper.new_sprint_long_sms(sprintSMS, user_phone)
		
		else

			if @user == nil || @user.carrier == SPRINT
				msg = sprintSMS 
			else #not Sprint
				msg = normalSMS 
			end 

			TwilioHelper.smsSend(msg, user_phone)

	 	end

	end  

	#doesn't sleep; relies on bkg worker async call in X seconds. 
	def self.new_text_no_wait(normalSMS, sprintSMS, user_phone)
		
		@user = User.find_by(phone: user_phone)

		#if sprint
		if (@user == nil || @user.carrier == SPRINT) && sprintSMS.length > 160

			TwilioHelper.new_sprint_long_sms(sprintSMS, user_phone)

		else

			if @user == nil || @user.carrier == SPRINT
				msg = sprintSMS 
			else #not Sprint
				msg = normalSMS 
			end 

			TwilioHelper.smsSend(msg, user_phone)

	 	end

	end  




	def self.new_sms_chain(smsArr, user_phone)
		@user = User.find_by(phone: user_phone)

		smsArr.each_with_index do |sms, index|

				if index + 1 != smsArr.length
					TwilioHelper.smsSend(sms, user_phone)
		    	else
					TwilioHelper.smsSend(sms, user_phone)
				end
 		end

 	end




end

