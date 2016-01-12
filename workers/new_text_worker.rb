require 'sinatra/activerecord'
require_relative '../models/user'           #add the user model
require 'sidekiq'

require_relative '../stories/story'
require_relative '../stories/storySeries'
require_relative '../helpers/twilio_helper'

require_relative '../i18n/constants'
require_relative '../helpers/sprint_helper'

require_relative './next_message_worker'

STORY = "story"

NOT_STORY  = "not story"


class NewTextWorker
  include Sidekiq::Worker
  include Text

  #Poll more often, so peeps rightly get their messages 
  Sidekiq.configure_server do |config|
    config.average_scheduled_poll_interval = 2
  end


    
    sidekiq_options :queue => :critical
    sidekiq_options retry: false #if fails, don't resent (multiple texts)

  def perform(sms, type, user_phone)

  	@user = User.find_by(phone: user_phone)

  	#candidate for Sprint chopped SMS
  	if sms.class == String && sms.length >= 160 && @user.carrier == Text::SPRINT
  		sms = Sprint.chop(sms)
  	elsif sms.class == String
  		TwilioHelper.smsSend(sms, @user.phone)  #send out normal text
  	end


  	if sms.class == Array && sms.length == 1 #transformed to Sprint array AND it's the last text
  		msg = sms.shift
  		TwilioHelper.new_text_no_wait(msg, msg, @user.phone)

      if type == STORY
        NextMessageWorker.updateUser(@user.phone, sms) #update user info
      end
      
  	elsif sms.class == Array && sms.length > 1  #not the last text
  		msg = sms.shift
  		TwilioHelper.new_text_no_wait(msg, msg, @user.phone)
  		NewTextWorker.perform_in(TwilioHelper::SMS_WAIT, sms, NOT_STORY, @user.phone)
  	end


 
  end




end