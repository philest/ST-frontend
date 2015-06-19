require 'rubygems'
require 'twilio-ruby'
require 'sinatra/activerecord'
require_relative '../../config/environments' #database configuration
require_relative '../../models/user'           #add the user model
require 'sidekiq'

require_relative '../../sprint'
require_relative '../../helpers'






FIRST = "FIRST"

FIRST_MMS = ["http://i.imgur.com/FfGSHjw.jpg", "http://i.imgur.com/f9x3lnN.jpg"]

FIRST_SMS = "StoryTime: Enjoy your first story about Brandon!"

SAMPLE_SMS = 'StoryTime: Thanks for trying out StoryTime, free stories by text! Your sample story is on the way :)'

class TestFirstTextWorker
  include Sidekiq::Worker



  sidekiq_options :queue => :critical

  sidekiq_options retry: false

  def perform(type, phoneNum) #Send the User the first poem shortly after first signup
  	

    @user = User.find_by(phone: phoneNum)

    if type == FIRST
      Helpers.test_new_mms(FIRST_SMS, FIRST_MMS, @user.phone)
    else
      Helpers.test_new_sms_first_mms(SAMPLE_SMS, FIRST_MMS, @user.phone)
    end

    puts "Sent Very First Story message to" + @user.phone + "\n\n"

  end


end
