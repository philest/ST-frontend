require 'twilio-ruby'

require_relative './app'

include ApplicationHelper

account_sid = ENV['TW_ACCOUNT_SID']
auth_token = ENV['TW_AUTH_TOKEN']

@client = Twilio::REST::Client.new account_sid, auth_token


#sends the signup story and text to the list of parents with given language
class Signup


	def self.initialize_user_count()
		@@user_num_story = 0
	end

	#params are a hasht that mimic the params in Application Enroll (eg params[:Carrier] -> Sprint
	def self.enroll(phone_nums, locale, *params)

		Signup.initialize_user_count()

		#retrieve from array
		if params != nil
			params = params.shift
		end

		phone_nums.each do |phone|

			ApplicationHelper.enroll(params, phone, locale, Signup.getWait)
			puts "enrolled #{phone}"
		end


	end



	def self.getWait()

		wait = @@user_num_story

    	@@user_num_story += 8

    	return wait

	end


end
