require 'rubygems'
require 'twilio-ruby'
require 'sinatra/activerecord'
require_relative '../models/user'           #add the user model
require 'sidekiq'

require_relative '../sprint'
require_relative '../stories/storySeries'

SPRINT_NAME_2 = "Sprint Spectrum, L.P."


PRO = "production"

class ChoiceWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :critical

  sidekiq_options retry: false

  def perform(phoneNum) #Send the User the first poem of their series just after choosing it
  
  	@user = User.find_by(phone: phoneNum)

    #set TWILIO credentials:
    account_sid = ENV['TW_ACCOUNT_SID']
    auth_token = ENV['TW_AUTH_TOKEN']

    @client = Twilio::REST::Client.new account_sid, auth_token

    #get the first poem in the series
    messageSeriesHash = MessageSeries.getMessageSeriesHash

    story = messageSeriesHash[@user.series_choice + @user.series_number.to_s][0]


    #Picture Messaging
  	#not SPRINT


      if @user.mms == true 
        TwilioHelper.new_mms(story.getSMS, story.getMmsArr[1..-1], @user.phone)
      end

      #already responded with text only stuff!

    #prep for next
    @user.update(next_index_in_series: @user.next_index_in_series + 1)
    
    #total message count
    @user.update(total_messages: @user.total_messages + 1)

  end


end




