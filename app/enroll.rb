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


#redis, for getting the experiment date
require 'redis'
require_relative '../config/environments'
require_relative '../config/initializers/redis'

#the models
require_relative '../models/user' #add User model
require_relative '../models/experiment' #add User model
require_relative '../models/variation' #add User model

require_relative '../experiment/experiment_constants'


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
		@user.update(days_per_week: 2)
	end

	#must manually set default time.
	@user.update(time: DEFAULT_TIME)


	## ASSIGN TO EXPERIMENT VARIATION
	#  -get first experiment
	#  -assign user to one of its variation
	#  -alternate variations using modulo
	#
	if type == STORY    #grab first experiment with users left to assign
		if Experiment.where("active = true").count != 0 &&
		  (our_experiment = Experiment.where("active = true AND users_to_assign != '0'").first)

			users_to_assign = our_experiment.users_to_assign

			#get valid variations from first experiment
			variations = our_experiment.variations

			#user-count used to alternate which variation chosen
			#Eg. with three variations:
			# u1 -> v1, u2 -> v2 ... u4 -> v1, u5 - > v2
			var = variations[users_to_assign % variations.count]
			@user.variation = var #give user the variation
			var.users.push @user #give variation the user

			#save to DB (TODO: necessary?)
			#update user with experiment variation


			case our_experiment.variable
			when ExperimentConstants::TIME_FLAG
				 @user.update(time: var.date_option)
			when ExperimentConstants::DAYS_TO_START_FLAG
				 @user.update(days_per_week: var.option.to_i)
			end

			#update exp time by popping off REDIS last days set
			if our_experiment.end_date == nil 
				our_experiment.update(end_date: Time.now.utc + 
								        REDIS
								       .rpop(DAYS_FOR_EXPERIMENT)
								       .to_i
								       .days)
			end


			#one more user was assigned
			our_experiment.update(users_to_assign: users_to_assign - 1)
		
			@user.save
			var.save
			our_experiment.save


		end

	end


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
