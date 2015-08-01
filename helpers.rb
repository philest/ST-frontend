require 'sinatra/r18n'

class Helpers

SPRINT = "Sprint Spectrum, L.P."

SMS_HELPER = "SMS_HELPER"
PRO = "production"
TEST ="test"
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
		Helpers.initialize_testing_vars
	end
 	
	# #Helpers that simply twiml REST API
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
   			
   			Helpers.smsRespondHelper(body)
   		end

	end

	def self.mmsRespond(mms_url, order)

		if @@mode == TEST || @@mode == TEST_CRED
			@@twiml_mms.push mms_url
		elsif @@mode == PRO
			Helpers.mmsRespondHelper(mms_url)
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
			Helpers.fullRespondHelper(body, mms_url)
		end

	end



   	def self.smsSend(body, user_phone, order)
		if @@mode == TEST || @@mode == TEST_CRED
			@@twiml = body
			@@twiml_sms.push body

			#turn on testcred
			Helpers.testCred
			#simulate actual REST api
			Helpers.smsSendHelper(body, user_phone)

		elsif @@mode == PRO
			Helpers.smsSendHelper(body, user_phone)
		end

   		sleep Helpers.getSleep(order, SMS)
   	end

   	def self.mmsSend(mms_url, user_phone, order)
		if @@mode == TEST || @@mode == TEST_CRED
			@@twiml_mms.push mms_url
			puts "Sent #{mms_url[18, mms_url.length]}"
		elsif @@mode == PRO
			Helpers.mmsSendHelper(mms_url, user_phone)
		end

   		sleep Helpers.getSleep(order, MMS)
   	end

   	def self.fullSend(body, mms_url, user_phone, order)

		#account for mms_url in arrays
    	if mms_url.class == Array
    		mms_url = mms_url[0]
    	end

		if @@mode == TEST || @@mode == TEST_CRED
			@@twiml_mms.push mms_url
			@@twiml_sms.push body
			puts "Sent #{mms_url[18, mms_url.length]}, #{body}"

		elsif @@mode == PRO
			Helpers.fullSendHelper(body, mms_url, user_phone)
		end

   		sleep Helpers.getSleep(order, MMS)
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
        	puts "TC: Sent sms to #{user_phone}: #{body[9, 18]}" 
       	else
    		puts "Sent sms to #{user_phone}: #{body[9, 18]}"
    	end 

		  #turn off testCred
	      Helpers.testCredOff
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

    	puts "Sent mms to #{user_phone}: #{mms_url[18, mms_url.length]}"
    end

    def self.fullSendHelper(body, mms_url, user_phone)
  
   		if @@mode == PRO
		    account_sid = ENV['TW_ACCOUNT_SID']
		    auth_token = ENV['TW_AUTH_TOKEN']
			@client = Twilio::REST::Client.new account_sid, auth_token
		end
          
          message = @client.account.messages.create(
            :body => body,
            :media_url => mms_url,
            :to => user_phone,     # Replace with your phone number
            :from => @@my_twilio_number)   # Replace with your Twilio number

        puts "Sent mms to #{user_phone}: #{mms_url[18, mms_url.length]}"
    	puts "along with sms: #{body[9, 18]}" 

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

    	Helpers.fullRespond(body, mms_url, LAST)
    end



	def self.mms(mms, user_phone)

    	@user = User.find_by(phone: user_phone)
		
		if @user == nil
    		puts "Sent mms to new user"
    	else
    		puts "Sent to #{@user.phone}: #{mms[18, mms.length]}" 
  		end


    	Helpers.mmsRespond(mms, LAST)

	end


	def self.text(normalSMS, sprintSMS, user_phone)
	
 		@user = User.find_by(phone: user_phone)


		#if sprint
		if (@user == nil || @user.carrier == SPRINT) && sprintSMS.length > 160


			sprintArr = Sprint.chop(sprintSMS)

			msg = sprintArr.shift #pop off first element


			FirstTextWorker.perform_in(14.seconds, SMS_HELPER, user_phone, sprintArr)


		elsif @user == nil || @user.carrier == SPRINT
			msg = sprintSMS 
		else
			msg = normalSMS
		end


		if (@@mode == TEST || @@mode == TEST_CRED) && ((@user == nil || @user.carrier == SPRINT) && sprintSMS.length > 160)
			FirstTextWorker.drain
		end

		if @user == nil
    		puts "Sent full to new user"
    	else
			puts "Sent sms to #{@user.phone}: " + "\"" + msg[0,18] + "...\""
  		end
		
		Helpers.smsRespond(msg, LAST)

	end  





	#RESPONSE Sprint SMS LONG

	#helper method to deliver sprint texts
	def self.new_sprint_long_sms(long_sms, user_phone)

		@user = User.find_by(phone: user_phone)

		sprintArr = Sprint.chop(long_sms)

        sprintArr.each_with_index do |text, index|  

			if index + 1 != sprintArr.length
        		Helpers.smsSend(text, user_phone, NORMAL)
	    	else
        		Helpers.smsSend(text, user_phone, LAST)
			end

			puts "Sent sms part #{index} to" + @user.phone + "\n\n"


        end

	end


	def self.new_sprint_long_sms_no_wait(long_sms, user_phone)

		@user = User.find_by(phone: user_phone)

		sprintArr = Sprint.chop(long_sms)

        sprintArr.each_with_index do |text, index|  

			if index + 1 != sprintArr.length
        		Helpers.smsSend(text, user_phone, NORMAL)
	    	else
        		Helpers.smsSend(text, user_phone, NO_WAIT)
			end

			puts "Sent sms part #{index} to" + @user.phone + "\n\n"


        end

	end






	def self.new_mms(sms, mms_array, user_phone)

		@user = User.find_by(phone: user_phone)

		#if long sprint mms + sms, send all images, then texts one-by-one
		if @user != nil && (@user.carrier == SPRINT && sms.length > 160)

			mms_array.each_with_index do |mms_url, index|
					
					Helpers.mmsSend(mms_url, user_phone, NORMAL)
		     	 	 #for all, because text follows
			end

			Helpers.new_sprint_long_sms(sms, user_phone)

		else

			mms_array.each_with_index do |mms, index|

				if index + 1 == mms_array.length #last image comes w/ SMS
				
					Helpers.fullSend(sms, mms, user_phone, LAST)

				else

					Helpers.mmsSend(mms, user_phone, NORMAL)

				end

			end

		end

	end





	def self.new_sms_sandwich_mms(first_sms, last_sms, mms_array, user_phone)

		@user = User.find_by(phone: user_phone)


		#if long sprint mms + sms, send all images, then texts one-by-one
		if @user != nil && (@user.carrier == SPRINT && sms.length > 160)

			Helpers.new_sprint_long_sms(sms, user_phone)

			mms_array.each_with_index do |mms_url, index|

				if index + 1 != mms_array.length
				Helpers.mmsSend(mms_url, user_phone, NORMAL)
		    	else
				Helpers.mmsSend(mms_url, user_phone, LAST)
				end

			end

		else
			#SMS first!

			Helpers.smsSend(first_sms, user_phone, NORMAL)

			Helpers.mms_array.each_with_index do |mms_url, index|


				if index + 1 == mms_array.length #send sms with mms on last story

					Helpers.fullSend(last_sms, mms_url, user_phone, LAST)

				else

					Helpers.mmsSend(mms_url, user_phone, NORMAL)

				end


			end

		end

	end














	def self.new_sms_first_mms(sms, mms_array, user_phone)

		@user = User.find_by(phone: user_phone)

		#if long sprint mms + sms, send all images, then texts one-by-one
		if @user != nil && (@user.carrier == SPRINT && sms.length > 160)

			Helpers.new_sprint_long_sms(sms, user_phone)

			sleep SMS_WAIT

			mms_array.each_with_index do |mms, index|

				Helpers.mmsSend(mms, user_phone)

				if index + 1 != mms_array.length

					Helpers.mmsSend(mms, user_phone, NORMAL)

		    	else
					Helpers.mmsSend(mms, user_phone, LAST)
				end

			end

		else
			#SMS first!

			Helpers.smsSend(sms, user_phone, NORMAL)

			mms_array.each_with_index do |mms, index|
			
				if index + 1 != mms_array.length
					Helpers.mmsSend(mms, user_phone, NORMAL)
		    	else
					Helpers.mmsSend(mms, user_phone, LAST)
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
					Helpers.mmsSend(mms, user_phone, NORMAL)
		    	else
					Helpers.mmsSend(mms, user_phone, LAST)
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
					Helpers.mmsSend(mms, user_phone, NORMAL)
		    	else
					Helpers.mmsSend(mms, user_phone, NO_WAIT)
				end

			end
	end





	#send a NEW, unprompted text-- NOT a response
	def self.new_text(normalSMS, sprintSMS, user_phone)
		
		@user = User.find_by(phone: user_phone)

		#if sprint
		if (@user == nil || @user.carrier == SPRINT) && sprintSMS.length > 160

			Helpers.new_sprint_long_sms(sprintSMS, user_phone)
		
		else

			if @user == nil || @user.carrier == SPRINT
				msg = sprintSMS 
			else #not Sprint
				msg = normalSMS 
			end 

			Helpers.smsSend(msg, user_phone, LAST)

	 	end

	end  

	#doesn't sleep; relies on bkg worker async call in X seconds. 
	def self.new_text_no_wait(normalSMS, sprintSMS, user_phone)
		
		@user = User.find_by(phone: user_phone)

		#if sprint
		if (@user == nil || @user.carrier == SPRINT) && sprintSMS.length > 160

			Helpers.new_sprint_long_sms(sprintSMS, user_phone)

		else

			if @user == nil || @user.carrier == SPRINT
				msg = sprintSMS 
			else #not Sprint
				msg = normalSMS 
			end 

			Helpers.smsSend(msg, user_phone, NO_WAIT)

	 	end

	end  




	def self.new_sms_chain(smsArr, user_phone)
		@user = User.find_by(phone: user_phone)

		smsArr.each_with_index do |sms, index|

				if index + 1 != smsArr.length
					Helpers.smsSend(sms, user_phone, NORMAL)
		    	else
					Helpers.smsSend(sms, user_phone, LAST)
				end
 		end

 	end




end

