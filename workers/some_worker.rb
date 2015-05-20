# require '.config/environments'
require 'rubygems'
require 'twilio-ruby'
require 'sinatra/activerecord'
require_relative '../models/user'           #add the user model
require 'sidekiq'
require 'sidetiq'



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

    User.all.each do |user|

    	
      if SomeWorker.sendStory?(user) 
    		message = @client.account.messages.create(:body => 
    		"StoryTime: the timed job worked!!",
    	    :to => user.phone,     # Replace with your phone number
    	    :from => "+17377778679")   # Replace with your Twilio number

        puts "Sent message to" + user.phone + "\n\n"

      end

    end

    puts "doing hard work!!" + "\n\n" 



  end


  # helper methods

  # check if user's story time is in the next two minutes
  def self.sendStory?(user) #don't know object as parameter

    currTime = SomeWorker.cleanSysTime
    userTime = SomeWorker.convertTimeTo24(user.time)

    currHour = currTime[0,2]
    userHour = userTime[0,2]

    len = currTime.length 
    # assert(currTime.length == userTime.length, "lengths differ")
    # assert(len == 5, "lengths differ")

      currMin = currTime[3, len]
      userMin = userTime[3, len]

      currMin = currMin.to_i
      userMin = userMin.to_i    

    if currHour == userHour #same hour

      if (userMin - currMin) < 2 && (userMin - currMin) >= 0 #send the message
        return true
      else
        return false
      end
    elsif (userHour.to_i == 1 + currHour.to_i) &&  
          ((currMin == 58 && userMin == 0) || (currMin == 59 && userMin == 1)) #the 5:58 send the 6:00 message
        return true
    else
      return false
    end

  end

  # returns a cleaned version of the current system time in 24 hour version
  def self.cleanSysTime

    currTime = Time.new

    hours = currTime.hour
    min = currTime.min

    # check if min is single digit
    if min < 10
      min = min.to_s
      min = "0"+min #add zero infront 
      cleanedTime = hours.to_s+":"+min #24 hour format- example 15:25
    else
      cleanedTime = hours.to_s+":"+min.to_s 
    end

    return cleanedTime
  end

  # converts pm/am time into 24hour time 
  def self.convertTimeTo24(oldTime)


    len = oldTime.length
    hoursEndIndex = oldTime.index(':')
    
    hours = oldTime[0,hoursEndIndex]

    colonAndMinutes = oldTime[hoursEndIndex, len-4]
      cleanedTime= hours + colonAndMinutes


    if oldTime[len-2,len] == "pm" && hours != "12" #if pm, add 12 to hours (unless noon)     

      hours = (hours.to_i + 12).to_s 

    elsif oldTime[len-2,len] == "pm" && hours == "12"

      cleanedTime = oldTime[0,len-2]

    else  #am version   

      cleanedTime = oldTime[0,len-2]

      if hours.to_i < 10 #add zero if single digit hour
        cleanedTime = "0" + cleanedTime
      end

     if hours == "12"   # 12:XXam convert to 00:XXam
        cleanedTime = "00" + colonAndMinutes
     end     

    end

    return cleanedTime

  end




end






  


  

