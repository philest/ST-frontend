
helpers do

	#ONLY A RESPONSE
	def text(normalSMS, sprintSMS)
	
		#if sprint
		if @user.carrier == SPRINT
			msg = sprintSMS 
		else
			msg = normalSMS
		end

		puts "Sent message to #{@user.phone}: " + "\"" + msg[0,18] + "...\""

		twiml = Twilio::TwiML::Response.new do |r|
	   		r.Message sprintSMS #SEND SPRINT MSG
	   	end
	    twiml.text

		sleep 1

	end  

	#helper method to deliver sprint texts
	def new_sprint_long_sms(long_sms, user_phone)

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



	def new_mms(sms, mms_array, user_phone)

		@user = User.find_by(phone: user_phone)


		#if long sprint mms + sms, send all images, then texts one-by-one
		if @user.carrier == SPRINT && sms.length > 160

			sprintArr = Sprint.chop(sms)

			mms_array.each_with_index do |mms_url, index|

					 message = @client.account.messages.create(
		                      :to => @user.phone,     # Replace with your phone number
		                      :from => "+17377778679",
		                      :mms_url => mms_url
		                      )

					 sleep 20
			end

			new_sprint_long_sms(sms, user_phone)

		else

			mms_array.each_with_index do |mms_url, index|

				if index + 1 == mms_array.length #last image
				
					 message = @client.account.messages.create(
		                      :to => @user.phone,     # Replace with your phone number
		                      :from => "+17377778679",
		                      :mms_url => mms_url,
		                      :body => sms
		                      )

					 sleep 10

				else

					 message = @client.account.messages.create(
		                      :to => @user.phone,     # Replace with your phone number
		                      :from => "+17377778679",
		                      :mms_url => mms_url
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


	#send a NEW, unprompted text-- NOT a response
	def new_text(normalSMS, sprintSMS, user_phone)
		
		@user = User.find_by(phone: user_phone)

		#if sprint
		if @user.carrier == SPRINT && sprintSMS.length > 160

			new_sprint_long_sms(sprintSMS, user_phone)

		elsif @user.carrier == SPRINT

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



 	def test_text(normalSMS, sprintSMS)

	 	#if sprint
		if @user.carrier == SPRINT

			@@twiml = sprintSMS

		else #not Sprint
			@@twiml = normalSMS
		end 

	end


end

