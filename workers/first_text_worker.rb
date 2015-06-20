require 'rubygems'
require 'twilio-ruby'
require 'sinatra/activerecord'
require_relative '../models/user'           #add the user model
require 'sidekiq'

require_relative '../sprint'
require_relative '../helpers'


SPRINT_NAME = "Sprint Spectrum, L.P."

FIRST = "FIRST"

FIRST_MMS = ["http://i.imgur.com/tqzsIqt.jpg", "http://i.imgur.com/f9x3lnN.jpg"]

FIRST_SMS = "StoryTime: Enjoy your first story about Brandon!"


SAMPLE_SMS = "Today, we talked about our favorite things to do outside. The kids all loved running. Keep sharing with tonight's story!\n-Ms. Wilson" 


GREET_SMS  = "StoryTime: Thanks for trying out StoryTime, free stories by text! Your two page sample story is on the way :)"


SAMPLE = "SAMPLE"

EXAMPLE = "EXAMPLE"

class FirstTextWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :critical

  sidekiq_options retry: false

  def perform(type, phoneNum) #Send the User the first poem shortly after first signup
                              #if SAMPLE, send the text first and a different message
  	
    @user = User.find_by(phone: phoneNum)

    #set TWILIO credentials:
    account_sid = ENV['TW_ACCOUNT_SID']
    auth_token = ENV['TW_AUTH_TOKEN']

    @client = Twilio::REST::Client.new account_sid, auth_token


    if type == FIRST
      Helpers.new_mms(FIRST_SMS, FIRST_MMS, @user.phone)
    elsif type == SAMPLE
      Helpers.new_mms(SAMPLE_SMS, FIRST_MMS, @user.phone)
    else
      Helpers.new_just_mms(FIRST_MMS, @user.phone)
    end

    puts "Sent Very First Story message to" + @user.phone + "\n\n"

  end

end
