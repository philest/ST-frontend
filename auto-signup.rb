
require_relative './app/enroll'

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
		else #no params
			params = {Carrier: "ATT"}
		end

		phone_nums.each do |phone|

			app_enroll(params, phone, locale, STORY, Signup.getWait)
			puts "enrolled #{phone}"
		end


	end



	def self.getWait()

		wait = @@user_num_story

    	@@user_num_story += 8

    	return wait

	end


end
