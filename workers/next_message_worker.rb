require 'sinatra/activerecord'
require_relative '../models/user'           #add the user model
require 'sidekiq'

require_relative '../message'
require_relative '../messageSeries'
require_relative '../helpers'

LAST = "last"
NORMAL = "normal"

class NextMessageWorker
  include Sidekiq::Worker
    
    sidekiq_options :queue => :critical
    sidekiq_options retry: false #if fails, don't resent (multiple texts)

  def perform(sms, mms_arr, user_phone)

  	@user = User.find_by(phone: user_phone)

  	if mms_arr.length == 1 #if last MMS, send with SMS
  		Helpers.fullSend(sms, mms_arr.shift, @user.phone, LAST)
  	else #not last MMS...
  		NextMessageWorker.perform_in(20.seconds, sms, mms_arr, @user.phone, NORMAL)
  	end



  end




end
