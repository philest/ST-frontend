

class Helpers


#testing goods
	def self.initialize_testing_vars
		@@twiml_sms = Array.new
	  	@@twiml_mms = Array.new
	  	@@twiml = ""
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


		#set TWILIO credentials:
	    account_sid = ENV['TW_ACCOUNT_SID']
	    auth_token = ENV['TW_AUTH_TOKEN']

    @client = Twilio::REST::Client.new account_sid, auth_token


	#ONLY A RESPONSE
	def self.text(normalSMS, sprintSMS, user_phone)
	
 		@user = User.find_by(phone: user_phone)

		#if sprint
		if @user == nil || @user.carrier == SPRINT
			msg = sprintSMS 
		else
			msg = normalSMS
		end

		puts "Sent message to #{@user.phone}: " + "\"" + msg[0,18] + "...\""

		twiml = Twilio::TwiML::Response.new do |r|
	   		r.Message msg #SEND SPRINT MSG
	   	end
	   	
	    twiml.text
	end  


	#helper method to deliver sprint texts
	def self.new_sprint_long_sms(long_sms, user_phone)

		@user = User.find_by(phone: user_phone)

		sprintArr = Sprint.chop(long_sms)

        sprintArr.each_with_index do |text, index|  
          message = @client.account.messages.create(
            :body => text,
            :to => @user.phone,     # Replace with your phone number
            :from => "+17377778679")   # Replace with your Twilio number

          puts "Sent sms part #{index} to" + @user.phone + "\n\n"

          sleep 10

        end

	end

	#helper test method to deliver sprint texts
	def self.test_new_sprint_long_sms(long_sms, user_phone)

		@user = User.find_by(phone: user_phone)

		Sprint.chop(long_sms).each_with_index do |text, index|  
	        @@twiml_sms.push text
        end

	end

	def self.test_new_mms(sms, mms_array, user_phone)

		@user = User.find_by(phone: user_phone)

		if @user == nil || (@user.carrier == SPRINT && sms.length > 160)

			mms_array.each_with_index do |mms_url, index|
				@@twiml_mms.push mms_url
			end
			test_new_sprint_long_sms(sms, user_phone)
		else

			mms_array.each_with_index do |mms_url, index|
				@@twiml_mms.push mms_url
			end

			@@twiml_sms.push sms

		end

	end


	def self.test_new_sms_sandwich_mms(first_sms, last_sms, mms_array, user_phone)

		@user = User.find_by(phone: user_phone)

		#if long sprint mms + sms, send all images, then texts one-by-one
		if @user != nil && (@user.carrier == SPRINT && sms.length > 160)

			test_new_sprint_long_sms(sms, user_phone)

			mms_array.each_with_index do |mms, index|
		          @@twiml_mms.push mms
			end

		else
			#SMS first!
			@@twiml_sms.push first_sms

			mms_array.each_with_index do |mms, index|
				@@twiml_mms.push mms
			end

			@@twiml_sms.push last_sms

		end

	end








	def self.new_sms_sandwich_mms(first_sms, last_sms, mms_array, user_phone)

		@user = User.find_by(phone: user_phone)


		#if long sprint mms + sms, send all images, then texts one-by-one
		if @user != nil && (@user.carrier == SPRINT && sms.length > 160)

			new_sprint_long_sms(sms, user_phone)

			mms_array.each_with_index do |mms_url, index|

					 message = @client.account.messages.create(
		                      :to => @user.phone,     # Replace with your phone number
		                      :from => "+17377778679",
		                      :media_url => mms_url
		                      )

					 sleep 20
			end


		else
			#SMS first!
			message = @client.account.messages.create(
	                  :to => @user.phone,     # Replace with your phone number
	                  :from => "+17377778679",
	                  :body => first_sms
	                  )

			sleep 13

			mms_array.each_with_index do |mms_url, index|


					 message = @client.account.messages.create(
		                      :to => @user.phone,     # Replace with your phone number
		                      :from => "+17377778679",
		                      :media_url => mms_url
		                      )

					 sleep 20
			end


					#SMS first!
			message = @client.account.messages.create(
	                  :to => @user.phone,     # Replace with your phone number
	                  :from => "+17377778679",
	                  :body => last_sms
	                  )

			sleep 3

		end

	end


	def self.test_new_sms_first_mms(sms, mms_array, user_phone)

		@user = User.find_by(phone: user_phone)

		#if long sprint mms + sms, send all images, then texts one-by-one
		if @user != nil && (@user.carrier == SPRINT && sms.length > 160)

			test_new_sprint_long_sms(sms, user_phone)

			mms_array.each_with_index do |mms, index|
		          @@twiml_mms.push mms
			end

		else
			#SMS first!
			@@twiml_sms.push sms

			mms_array.each_with_index do |mms, index|
				@@twiml_mms.push mms
			end

		end

	end







	def self.new_mms(sms, mms_array, user_phone)

		@user = User.find_by(phone: user_phone)


		#if long sprint mms + sms, send all images, then texts one-by-one
		if @user == nil || (@user.carrier == SPRINT && sms.length > 160)

			mms_array.each_with_index do |mms_url, index|

					 message = @client.account.messages.create(
		                      :to => @user.phone,     # Replace with your phone number
		                      :from => "+17377778679",
		                      :media_url => mms_url
		                      )

					 sleep 20
			end

			new_sprint_long_sms(sms, user_phone)

		else

			mms_array.each_with_index do |mms, index|

				if index + 1 == mms_array.length #last image
				
					 message = @client.account.messages.create(
		                      :to => @user.phone,     # Replace with your phone number
		                      :from => "+17377778679",
		                      :media_url => mms,
		                      :body => sms
		                      )

					 sleep 10

				else

					 message = @client.account.messages.create(
		                      :to => @user.phone,     # Replace with your phone number
		                      :from => "+17377778679",
		                      :media_url => mms
		                      )

					 sleep 20
				end

			end

		end

	end


	# def new_single_mms(sms, mms, user_phone)

	# 	@user = User.find_by(phone: user_phone)
		
	# 	if @user.carrier == SPRINT && sms.length > 160

	# 		sprintArr = Sprint.chop(sms)
 		
 # 			message = @client.account.messages.create(
 #                      :to => @user.phone,     # Replace with your phone number
 #                      :from => "+17377778679",
 #                      :mms_url => mms
 #                      )

 # 			sleep 20

 # 			sprintArr.each do |sprint_chunk|

 # 			 message = @client.account.messages.create(
 #                      :to => @user.phone,     # Replace with your phone number
 #                      :from => "+17377778679",
 #                      :body => sprint_chunk
 #                      )

 # 			 sleep 10

 # 			end

 # 		else

 # 			message = @client.account.messages.create(
 #                      :to => @user.phone,     # Replace with your phone number
 #                      :from => "+17377778679",
 #                      :mms_url => mms,
 #                      :body => sms
 #                      )

 # 			sleep 10

 # 		end

 # 	end


	def self.test_new_text(normalSMS, sprintSMS, user_phone)
		
		@user = User.find_by(phone: user_phone)

		#if sprint
		if (@user == nil || @user.carrier == SPRINT) && sprintSMS.length > 160

			test_new_sprint_long_sms(sprintSMS, user_phone)

		elsif @user == nil || @user.carrier == SPRINT

			@@twiml_sms.push sprintSMS 

		else #not Sprint

			@@twiml_sms.push normalSMS 

		end 

		puts "Sent message to #{@user.phone}: " + "\"" + msg[0,18] + "...\""

	end  




	#send a NEW, unprompted text-- NOT a response
	def self.new_text(normalSMS, sprintSMS, user_phone)
		
		@user = User.find_by(phone: user_phone)

		#if sprint
		if (@user == nil || @user.carrier == SPRINT) && sprintSMS.length > 160

			new_sprint_long_sms(sprintSMS, user_phone)

		elsif @user == nil || @user.carrier == SPRINT

			msg = sprintSMS 

 			message = @client.account.messages.create(
                      :body => msg,
                      :to => @user.phone,     # Replace with your phone number
                      :from => "+17377778679")

		else #not Sprint

			msg = normalSMS 

 			message = @client.account.messages.create(
                      :body => msg,
                      :to => @user.phone,     # Replace with your phone number
                      :from => "+17377778679")
		end 

		puts "Sent message to #{@user.phone}: " + "\"" + msg[0,18] + "...\""

		sleep 1


	end  



 	def self.test_text(normalSMS, sprintSMS, user_phone)

 		@user = User.find_by(phone: user_phone)

	 	#if sprint
		if @user == nil || @user.carrier == SPRINT

			@@twiml = sprintSMS
			@@twiml_sms.push sprintSMS

		else #not Sprint
			@@twiml = normalSMS
			@@twiml_sms.push normalSMS

		end 

	end


end

