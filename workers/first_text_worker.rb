require 'rubygems'
require 'twilio-ruby'
require 'sinatra/activerecord'
require_relative '../models/user'           #add the user model
require 'sidekiq'

require_relative '../sprint'


SPRINT_NAME = "Sprint Spectrum, L.P."


FIRST_MMS = "http://i.imgur.com/IzpnamS.png"

FIRST_SMS = "StoryTime: Here's your first poem! Act out each orange word as you read aloud. 

Activities:

a) Ask your child if they can make a convincing owl hoot.

b) What part of the body do you use to speak? To hear? To know?

If this picture msg was unreadable, reply TEXT for text-only stories."


class FirstTextWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(phoneNum) #Send the User the first poem shortly after first signup
  	@user = User.find_by(phone: phoneNum)


    #set TWILIO credentials:
    account_sid = ENV['TW_ACCOUNT_SID']
    auth_token = ENV['TW_AUTH_TOKEN']

    @client = Twilio::REST::Client.new account_sid, auth_token





  	#SPRINT
  	if @user.carrier == SPRINT_NAME

  		sprintArr = Sprint.chop(FIRST_SMS)

  		                #send single picture
                message = @client.account.messages.create(
                    :to => @user.phone,     # Replace with your phone number
                    :from => "+17377778679",
                    :media_url => FIRST_MMS)   # Replace with your Twilio number

                sleep 15

                sprintArr.each_with_index do |text, index|  
                  message = @client.account.messages.create(
                    :body => text,
                    :to => @user.phone,     # Replace with your phone number
                    :from => "+17377778679")   # Replace with your Twilio number

                  puts "Sent message part #{index} to" + @user.phone + "\n\n"

                  sleep 2

          		end
    else #NORMAL
                  message = @client.account.messages.create(
                    :media_url => FIRST_MMS,
                    :body => FIRST_SMS,
                    :to => @user.phone,     # Replace with your phone number
                    :from => "+17377778679")   # Replace with your Twilio number

                  puts "Sent message to" + @user.phone + "\n\n"

                  sleep 2
	end

  end


end
