require 'rubygems'
require 'twilio-ruby'
require 'siantra/activerecord'
require_relative './config/environments' #database configuration
require_relative './models/user' #add the user model

SPRINT = "Sprint Spectrum, L.P."

account_sid = ENV['TW_ACCOUNT_SID']
auth_token = ENV['TW_AUTH_TOKEN']

MMSARR = ["http://i.imgur.com/FfGSHjw.jpg", "http://i.imgur.com/f9x3lnN.jpg"]


@client = Twilio::REST::Client.new account_sid, auth_token

parents = ["bleh"]

parents.each do |phone|

	@user = User.create(phone: phone)


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



    	# Lookup wireless carrier
    	#setup Twilio user account
	  	number = @client.phone_numbers.get(@user.phone, type: 'carrier')
	  	@user.carrier = number.carrier['name']
	  	@user.save

	if (@user.carrier == SPRINT)

	message = @client.account.messages.create(
		:body => "Hi! Your child's preK paid for you to get StoryTime, preK stories by text. You'll get 2 free stories/week-- the first is on the way!\n\nTo stop, reply STOP NOW",
		:to => phone,     # Replace with your phone number
	    :from => "+17377778679"
	    )   # Replace with your Twilio number
	puts message.sid

	else

	message = @client.account.messages.create(
		:body => "StoryTime: Hi! Your child's preK paid for you to get StoryTime, preK stories by text. You'll get 2 free stories/week-- the first is on the way!\n\nReply STOP NOW to stop or HELP NOW for help",
		:to => phone,     # Replace with your phone number
	    :from => "+17377778679"
	    )   # Replace with your Twilio number
	puts message.sid

	end

	sleep 12

		#part 1 
		message = @client.account.messages.create(
		:to => phone,     # Replace with your phone number
	    :from => "+17377778679",
	    :media_url => MMSARR[0]
	    )   # Replace with your Twilio number
	puts message.sid

	sleep 18

	#part 2 
		message = @client.account.messages.create(
		:to => phone,     # Replace with your phone number
	    :from => "+17377778679",
	    :media_url => MMSARR[1],
	    :body => "StoryTime: Enjoy your first story about Brandon!"
	    )

	       # Replace with your Twilio number
	puts message.sid


end
