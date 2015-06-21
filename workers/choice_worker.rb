require 'rubygems'
require 'twilio-ruby'
require 'sinatra/activerecord'
require_relative '../models/user'           #add the user model
require 'sidekiq'

require_relative '../sprint'
require_relative '../messageSeries'

SPRINT_NAME_2 = "Sprint Spectrum, L.P."


class ChoiceWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :critical

  sidekiq_options retry: false

  def perform(mode, phoneNum) #Send the User the first poem of their series just after choosing it
  
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


    if mode == PRO
      if @user.mms == true 

        Helpers.new_mms(story.getSMS, story.getMmsArr, @user.phone)

      else 
        Helpers.new_text(story.getPoemSMS, story.getPoemSMS, @user.phone)
      
      end

    else #test

      if @user.mms == true 

        Helpers.test_new_mms(story.getSMS, story.getMmsArr, @user.phone)

      else 

        Helpers.test_new_text(story.getPoemSMS, story.getPoemSMS, @user.phone)

      end
    end

    #prep for next
    @user.update(next_index_in_series: @user.next_index_in_series + 1)

  end


end




