require 'sinatra/activerecord'
require_relative '../models/user'           #add the user model
require 'sidekiq'

require_relative '../message'
require_relative '../messageSeries'
require_relative '../helpers'

require_relative '../constants'
require_relative '../sprint'


class NewTextWorker
  include Sidekiq::Worker
  include Text

  #Poll more often, so peeps rightly get their messages 
  Sidekiq.configure_server do |config|
    config.average_scheduled_poll_interval = 2
  end


    
    sidekiq_options :queue => :critical
    sidekiq_options retry: false #if fails, don't resent (multiple texts)

  def perform(sms, user_phone)

  	@user = User.find_by(phone: user_phone)

  	#candidate for Sprint chopped SMS
  	if sms.class == String && sms.length >= 160 && @user.carrier == Text::SPRINT
  		sms = Sprint.chop(sms)
  	elsif sms.class == String
  		Helpers.new_text_no_wait(sms, sms, @user.phone)  #send out normal text
  	end


  	if sms.class == Array && sms.length == 1 #transformed to Sprint array AND it's the last text
  		msg = sms.shift
  		Helpers.new_text_no_wait(msg, msg, @user.phone)
  	elsif sms.class == Array && sms.length > 1  #not the last text
  		msg = sms.shift
  		Helpers.new_text_no_wait(msg, msg, @user.phone)
  		NewTextWorker.perform_in(Helpers::SMS_WAIT, sms, @user.phone)
  	end


 
  end




end