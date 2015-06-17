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

      if @user.carrier != SPRINT_NAME_2 || story.getSMS < 160

          story.getMmsArr.each_with_index do |mms_url, index|

                    if (index + 1) < story.getMmsArr.length #Not the last image yet

                      message = @client.account.messages.create(
                      :to => @user.phone,     # Replace with your phone number
                      :from => "+17377778679",
                      :media_url => mms_url
                      )   # Replace with your Twilio number

                      sleep 20

                    else

                      message = @client.account.messages.create(
                      :to => @user.phone,     # Replace with your phone number
                      :from => "+17377778679",
                      :media_url => mms_url,
                      :body => story.getSMS

                      )   # Replace with your Twilio number

                      sleep 2

                    end
          end

      else #SPRINT

              sprintArr = Sprint.chop(story.getSMS)

              story.getMmsArr.each do |mms_url|
                     
                      message = @client.account.messages.create(
                      :to => @user.phone,     # Replace with your phone number
                      :from => "+17377778679",
                      :media_url => mms_url
                      )   # Replace with your Twilio number

                      sleep 20
              end

              sprintArr.each do |sms|

                      message = @client.account.messages.create(
                      :to => @user.phone,     # Replace with your phone number
                      :from => "+17377778679",
                      :body => sms
                    )

                      sleep 10
              end

      end

    else 

      puts "Haven't yet enabled SMS version"

    end

  end

end




