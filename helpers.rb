
helpers do

	#ONLY A RESPONSE
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

		sleep 1

	end  



	def new_many_mms(sms, mms_array, user_phone)

		@user = User.find_by(phone: user_phone)

		#if long sprint mms + sms, send all images, then texts one-by-one
		if @user.carrier == SPRINT && sms.length > 160






		end 	

	end

	#send a NEW, unprompted text-- NOT a response
	def new_text(normalSMS, sprintSMS, user_phone)
		
		@user = User.find_by(phone: user_phone)

		#if sprint
		if @user.carrier == SPRINT

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

