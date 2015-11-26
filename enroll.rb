#  enroll.rb 	                              Phil Esterman		
# 
#  Enroll the user for stories. 
#  --------------------------------------------------------

# Enroll the user for stories.
#	@param params => fake user data:
# 	  [Carrier: "ATT", Body: "BREAK"] etc. 
#   	-(For TEST mode. Normally given by Twilio.)	
#   @param user_phone => phone number: "+15614449999"
#   @param locale => language: "en"
#   @param (wait_time) => async wait to send: [14]
# 		-(for manual signup)

def app_enroll(params, user_phone, locale, *wait_time) 

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
		i18n = R18n::I18n.new(locale, ::R18n.default_places)
        R18n.thread_set(i18n)
	end

	#They texted to signup, so RESPOND.
	#NOTE! TODO This isn't configured for spanish, which require a two page Sprint response! 
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
