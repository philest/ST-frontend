#  app/enroll.rb 	                          Phil Esterman		
# 
#  Enroll the user for stories. 
#  --------------------------------------------------------

require 'twilio-ruby'

#internationalization
require 'sinatra/r18n'
#set default locale to english
# R18n.default_places = '../i18n/'
R18n::I18n.default = 'en'

translations_path = File.expand_path(File.dirname(__FILE__) + '/../i18n')
R18n.default_places { translations_path }

#temp: constants not yet translated
require_relative '../constants'
#constants (untranslated)
include Text

#timing
require 'time'
require_relative '../lib/set_time'

#sending messages
require_relative '../workers/next_message_worker'
require_relative '../helpers.rb'


SAMPLE = "sample"
STORY = "story"

MODE ||= ENV['RACK_ENV']
PRO ||= "production"
TEST ||= "test"

#configure Twilio
account_sid ||= ENV['TW_ACCOUNT_SID']
auth_token ||= ENV['TW_AUTH_TOKEN']
@client ||= Twilio::REST::Client.new account_sid, auth_token


# Enroll the user for stories.
#	@param params => fake user data:
# 	  [Carrier: "ATT", Body: "BREAK"] etc. 
#   	-(For TEST mode. Normally given by Twilio.)	
#   @param user_phone => phone number: "+15614449999"
#   @param locale => language: "en"
# 	@param type => sample or story: SAMPLE
#   @param (wait_time) => async wait to send: [14]
# 		-(for manual signup)

def app_enroll(params, user_phone, locale, type, *wait_time) 

	@user = User.find_by_phone(user_phone) #check if already registered.

	if @user == nil
		@user = User.create(phone: user_phone, locale: locale)
	end

	#PRO, set locale for returning user 
	if locale != nil && @user != nil
		i18n = R18n::I18n.new(@user.locale, ::R18n.default_places)
        R18n.thread_set(i18n)
	 	#set the locale for that user, w/in this thread
	end

	if type == STORY
		@user.update(sample: false)
		@user.update(subscribed: true) 
		@user.update(locale: locale)
	elsif type == SAMPLE
		@user.update(sample: true)
		@user.update(subscribed: false)
	end

	if type == STORY
		if MODE == PRO #only relevant for production code
			#randomly assign to get two days a week or three days a week
			if (rand = Random.rand(9)) == 0
				@user.update(days_per_week: 1)
			else @user.update(days_per_week: 2)
			end
		else @user.update(days_per_week: 2)
		end
	end

	# #update subscription
	# @user.update(subscribed: true) #Subscription complete! (B/C defaults)
	# #backup for defaults

	#must manually set default time.
	@user.update(time: DEFAULT_TIME)


	if MODE == PRO
   		account_sid = ENV['TW_ACCOUNT_SID']
    	auth_token = ENV['TW_AUTH_TOKEN']
	  	@client = Twilio::REST::LookupsClient.
	  				new account_sid, auth_token
    	# Lookup wireless carrier if not already done in SAMPLE
    	if @user.carrier == nil
		  	number = @client.phone_numbers.
		  				get(@user.phone, type: 'carrier')
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

	#NOT manually enrolled: respond to their signup text!
	#NOTE! TODO This isn't configured for spanish, which require a two page Sprint response! 
	if type == STORY
		if params && params[:Body] != nil
		  	if @user.carrier == Text::SPRINT
		  		Helpers.text_and_mms(R18n.t.start.sprint(days),
		  			R18n.t.first_mms.to_s, @user.phone)
		  	else
		  		Helpers.text_and_mms(R18n.t.start.normal(days),
		  			R18n.t.first_mms.to_s, @user.phone)
		  	end
		  	#update total message count 
		  	#NOTE: NextMessageWorker does it for auto-enrolled.
		  	@user.update(total_messages: 1)
		else #SEND NEW text, not response.
			wait_time = wait_time.shift
			if @user.carrier == Text::SPRINT				
		  		NextMessageWorker.perform_in(wait_time.seconds,
		  							 R18n.t.start.sprint(days), 
		  				    R18n.t.first_mms.to_s, @user.phone)
		  	else
		  		NextMessageWorker.perform_in(wait_time.seconds,
		  			                 R18n.t.start.normal(days),
		  					R18n.t.first_mms.to_s, @user.phone)
		  	end
		end
	elsif type == SAMPLE
		if params[:Body].casecmp(R18n.t.commands.sample) == 0 
		  	if @user.carrier == Text::SPRINT
				Helpers.text_and_mms(R18n.t.sample.sprint.to_s, R18n.t.first_mms.to_s, @user.phone)
			else
				Helpers.text_and_mms(R18n.t.sample.normal.to_s, R18n.t.first_mms.to_s, @user.phone)
			end
		elsif params[:Body].casecmp(R18n.t.commands.example) == 0 
			Helpers.text_and_mms(R18n.t.example, R18n.t.first_mms, @user.phone) 
		end
	end

end
