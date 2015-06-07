require 'rubygems'
require 'twilio-ruby'
require 'sinatra/activerecord'
require_relative '../models/user'           #add the user model
require 'sidekiq'

require_relative '../sprint'


SPRINT_NAME = "Sprint Spectrum, L.P."


FIRST_MMS =  ["http://i.imgur.com/2SU3JaA.jpg", "http://i.imgur.com/xVN3dFI.jpg"]


FIRST_SMS = "StoryTime: Your first poem's full of rhymes, which help your child build reading skills. When you reach an orange line, let your child say the rhyme! 

Activity:

Elephants have floppy ears. See what sounds you can add to the beginning of \“ear\”— like \”fear\” & \”dear.\” Take turns, and make up some words!"

class FirstTextWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :critical

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
                    :media_url => FIRST_MMS[0])   # Replace with your Twilio number

                sleep 20

                message = @client.account.messages.create(
                    :to => @user.phone,     # Replace with your phone number
                    :from => "+17377778679",
                    :media_url => FIRST_MMS[1])   # Replace with your Twilio number

                sleep 15


                sprintArr.each_with_index do |text, index|  
                  message = @client.account.messages.create(
                    :body => text,
                    :to => @user.phone,     # Replace with your phone number
                    :from => "+17377778679")   # Replace with your Twilio number

                  puts "Sent message part #{index} to" + @user.phone + "\n\n"

                  sleep 7

          		  end
    else #NORMAL


                   #send first picture
                message = @client.account.messages.create(
                    :to => @user.phone,     # Replace with your phone number
                    :from => "+17377778679",
                    :media_url => FIRST_MMS[0])   # Replace with your Twilio number

                sleep 20

                  message = @client.account.messages.create(
                    :media_url => FIRST_MMS[1],
                    :body => FIRST_SMS,
                    :to => @user.phone,     # Replace with your phone number
                    :from => "+17377778679")   # Replace with your Twilio number

                  puts "Sent message to" + @user.phone + "\n\n"

                  sleep 1

    end

  end

end
