require 'rubygems'
require 'twilio-ruby'
require 'sinatra/activerecord'
require_relative '../../config/environments' #database configuration
require_relative '../../models/user'           #add the user model
require 'sidekiq'

require_relative '../../sprint'
require_relative '../../helpers'







SPRINT_NAME = "Sprint Spectrum, L.P."

FIRST_MMS = ["http://i.imgur.com/FfGSHjw.jpg", "http://i.imgur.com/f9x3lnN.jpg"]

FIRST_SMS = "StoryTime: Enjoy your first story about Brandon!"

class TestFirstTextWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :critical

  sidekiq_options retry: false

  def perform(phoneNum) #Send the User the first poem shortly after first signup
  	
    @user = User.find_by(phone: phoneNum)

    test_new_mms(FIRST_SMS, FIRST_MMS, @user.phone)

    puts "Sent Very First Story message to" + @user.phone + "\n\n"

  end

end
