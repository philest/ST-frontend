# require '.config/environments'
require 'rubygems'
require 'twilio-ruby'
 

class SomeWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable
	
	sidekiq_options retry: false #if fails, don't resent (multiple texts)


  recurrence { hourly.minute_of_hour(0, 2, 4, 6, 8, 10,
  									12, 14, 16, 18, 20, 22, 24, 26, 28, 30,
  									32, 34, 36, 38, 40, 42, 44, 46, 48, 50,
  									52, 54, 56, 58) } #set explicitly because of ice-cube sluggishness

  def perform(*args)
    
    account_sid = ENV['TW_ACCOUNT_SID']
    auth_token = ENV['TW_AUTH_TOKEN']

  	@client = Twilio::REST::Client.new account_sid, auth_token

  	# send Twilio message
  	if false == true 
		message = @client.account.messages.create(:body => 
		"StoryTime: the timed job worked!",
	    :to => "+15612125831",     # Replace with your phone number
	    :from => "+17377778679")   # Replace with your Twilio number
	end

    puts "doing hard work!!"


  end



end

