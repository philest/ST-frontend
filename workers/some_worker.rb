# require '.config/environments'
require 'rubygems'
require 'twilio-ruby'
require 'sinatra/activerecord'
require_relative '../models/user'           #add the user model
require 'sidekiq'
require 'sidetiq'

require_relative '../sprint'
require_relative '../message'
require_relative '../messageSeries'
require_relative '../helpers'

class SomeWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable
  
  sidekiq_options :queue => :default


  MAX_TEXT = 155 #leaves room for (1/6) at start (160 char msg)
  
  TIME_SMS_NORMAL = "StoryTime: Hey there! We want to make StoryTime better for you. When do you want to receive stories (e.g. 5:00pm)?

  Rememeber screentime within 2hrs before bedtime can delay children's sleep and carry health risks, so please read earlier."

  TIME_SMS_SPRINT_1 = "(1/2)\nStoryTime: Hi! We want to make StoryTime better for you. When do you want to receive stories (e.g. 5:00pm)?"

  TIME_SMS_SPRINT_2 = "(2/2)\nRememeber screentime within 2hrs before bedtime can delay children's sleep and carry health risks, so please read earlier."

  BIRTHDATE_UPDATE = "StoryTime: If you want the best stories for your child's age, reply with your child's birthdate in MMYY format (e.g. 0912 for September 2012)."

  DAY_LATE = "StoryTime: Hi! We noticed you didn't choose your last story. To continue getting StoryTime stories, just reply \"yes\"\n\nThanks :)"

  DROPPED = "We haven't heard from you, so we'll stop sending you messages. To get StoryTime again, reply with STORY"

  SERIES_CHOICES = ["StoryTime: Hi! You can now choose new stories. Do you want stories about Marley the puppy or about Bruce the moose?\n\nReply \"p\" for puppy or \"m\" for moose."]


  #time for the birthdate and time updates: NOTE, EST set.
  if ENV['MY_MACHINE?'] == "true" #my machine
    UPDATE_TIME = "16:00"
    UPDATE_TIME_2 = "16:01"

  else #on the INTERNET
    UPDATE_TIME = "20:00" 
    UPDATE_TIME_2 = "20:00"

  end

	sidekiq_options retry: false #if fails, don't resent (multiple texts)


  recurrence { hourly.minute_of_hour(0, 2, 4, 6, 8, 10,
  									12, 14, 16, 18, 20, 22, 24, 26, 28, 30,
  									32, 34, 36, 38, 40, 42, 44, 46, 48, 50,
  									52, 54, 56, 58) } #set explicitly because of ice-cube sluggishness


  def perform(*args)

    mode = ENV['RACK_ENV']

    account_sid = ENV['TW_ACCOUNT_SID']
    auth_token = ENV['TW_AUTH_TOKEN']

    @client = Twilio::REST::Client.new account_sid, auth_token

    #logging
    puts "\nSystemTime: " + SomeWorker.cleanSysTime + "\n"

    #logging
    puts "\nSend story?: \n"

    # send Twilio message
    # only for subscribed
    User.where(subscribed: true).find_each do |user|

      #logging info
      puts  user.phone + " with time " + SomeWorker.convertTimeTo24(user.time) + ": "
      if SomeWorker.sendStory?(user)
        puts 'YES!!'
      else
        puts 'No.'
      end

      #UPDATE time
      if user.set_time == false && (SomeWorker.cleanSysTime == UPDATE_TIME || SomeWorker.cleanSysTime == UPDATE_TIME_2)  && user.total_messages == 2 #Customize time 
          
        if user.carrier == SPRINT

          Helpers.new_text(mode, TIME_SMS_SPRINT_1, TIME_SMS_SPRINT_1, user.phone)
          sleep 10
          Helpers.new_text(mode, TIME_SMS_SPRINT_2, TIME_SMS_SPRINT_2, user.phone)

        else #NORMAL carrier

          Helpers.new_text(mode, TIME_SMS_NORMAL, TIME_SMS_NORMAL, user.phone)

        end

      end



      #UPDATE Birthdate! 
      if user.set_birthdate == false && (SomeWorker.cleanSysTime == UPDATE_TIME || SomeWorker.cleanSysTime == UPDATE_TIME_2) && user.total_messages == 4 #Customize time 



        Helpers.new_text(mode, BIRTHDATE_UPDATE, BIRTHDATE_UPDATE, user.phone)
        
      end


        if SomeWorker.sendStory?(user) 

         #Should the user be asked to choose a series?
          #If it's all of these:
          #0) not awaiting chioce
          #a) their time, 
          #b) their third story, or every third one thereafter.
          #c) they're not in the middle of a series
          if user.awaiting_choice == false && ((user.story_number == 1 || (user.story_number != 0 && (user.story_number + 1) % 3 == 0)) && user.next_index_in_series == nil)

            #get set for first in series
            user.update(next_index_in_series: 0)
            user.update(awaiting_choice: true)

            #choose a series
            Helpers.new_text(SERIES_CHOICES[user.series_number], SERIES_CHOICES[user.series_number], user.phone)

          elsif user.awaiting_choice == true && user.next_index_in_series == 0 # the first time they haven't responded
          
            
            Helpers.new_text(DAY_LATE, DAY_LATE, user.phone)
            user.update(next_index_in_series: 999)  

          elsif user.next_index_in_series == 999 #the second time they haven't responded

             user.update(subscribed: false)
             Helpers.new_text(DROPPED, DROPPED, user.phone)

          #send STORY or SERIES, but not if awaiting series response
          elsif (user.series_choice == nil && user.next_index_in_series == nil) || user.series_choice != nil

            #get the story and series structures
            messageArr = Message.getMessageArray
            messageSeriesHash = MessageSeries.getMessageSeriesHash

            #SERIES
            if user.series_choice != nil
              story = messageSeriesHash[user.series_choice + user.series_number.to_s][user.next_index_in_series]
            #STORY
            else 
              story = messageArr[user.story_number]
            end 
          

            #JUST SMS MESSAGING!
            if user.mms == false

                Helpers.new_text(story.getPoemSMS, story.getPoemSMS, user.phone)

            else #MULTIMEDIA MESSAGING (MMS)!

                Helpers.new_mms(story.getSMS, story.getMmsArr, user.phone)

            end#MMS or SMS

              #updating story or series number
              #next_index_in_series == nil (or series_choice == nil?) means that you're not in a series
              if user.next_index_in_series != nil
                user.update(next_index_in_series: (user.next_index_in_series + 1))

                #exit series if time's up
                if user.next_index_in_series == messageSeriesHash[user.series_choice + user.series_number.to_s].length

                  ##return variable to nil: (nil, which means "you're asking the wrong question-- I'm not in a series")
                  user.update(next_index_in_series: nil)
                  user.update(series_choice: nil)

                  #get ready for next series
                  user.update(series_number: user.series_number + 1)

                end

              else
                user.update(story_number: user.story_number + 1)
              end

              #total message count
              user.update(total_messages: user.total_messages + 1)

          end#end story_subpart

        end#end sendStory? large

    end#end User.do

        
    puts "doing hard work!!" + "\n\n" 

  end #end perform method



  # converts one long 160+ character string into an array of <160 char strings
  def self.sprint(story) 

    sms = Array.new #array of texts to send seperately

    storyLen = story.length #characters in story

    totalChar = 0 #none counted so far

    startIndex = 0 

    smsNum = 1 #which sms you're on (starts with first)

    while (totalChar < storyLen - 1) #haven't divided up entire message yet

      if (totalChar + MAX_TEXT < storyLen) #if not on last message
        endIndex = startIndex + MAX_TEXT  
      else #if on last message
        endIndex = storyLen - 1 #endIndex is last index of story
      end

        while (story[endIndex-1] != "\n" || endIndex-1 == startIndex) && endIndex != storyLen-1 do  #find the latest newline before endIndex
          endIndex -= 1
        end

        if endIndex == startIndex #no newlines in block


          endIndex = startIndex + MAX_TEXT #recharge endindex
          
          while story[endIndex-1] != " "
          endIndex -= 1
          end

        end

      smsLen = endIndex - startIndex #chars in sms

      totalChar += smsLen #chars dealt with so far

      sms.push "(#{smsNum}/X)"+story[startIndex, smsLen]

      startIndex = endIndex

      smsNum += 1 #on the next message

    end

    sms.each do |text|
      text.gsub!(/[\/][X][)]/, "\/#{smsNum-1})")
    end

    return sms

  end



  #makes a hash to use in struct
  def self.makeHash(three, four, five)
    hash = { 3 => three, 4 => four, 5 => five}
    return hash
  end

  # helper methods

  # check if user's story time is in the next two minutes
  def self.sendStory?(user) #don't know object as parameter

    weekday = Time.new.wday 

    one_day_age = Time.now - 1.day

    
    if (((user.days_per_week == 3 && (weekday == 1 || weekday == 3 || weekday == 5)) || (user.days_per_week == 1 && (weekday == 3)) || ((user.days_per_week == 2 || user.days_per_week == nil) && (weekday == 2 || weekday == 4))) && (user.created_at <= one_day_age)) ||
      (user.phone == "+15612125831" || user.phone == "+15619008225") #SEND TO US EVERYDAY
                                                                     #SEND IF TUES OR THURS and NOT created this past day!
                                                                    #Note: this messes up if they created this past 5:00pm on a M or W
      currTime = SomeWorker.cleanSysTime
      userTime = SomeWorker.convertTimeTo24(user.time)

      currHour = currTime[0,2]   
      userHour = userTime[0,2]

      #CONVERTING FROM EASTERN TO UTC when not my machine!!!!
      if ENV['MY_MACHINE?'] != "true"
      userHour = ((userTime[0,2].to_i + 4) % 24).to_s
      end


      len = currTime.length 
      # assert(currTime.length == userTime.length, "lengths differ")
      # assert(len == 5, "lengths differ")

        currMin = currTime[3, len]
        userMin = userTime[3, len]

        currMin = currMin.to_i
        userMin = userMin.to_i    

      if currHour.to_i == userHour.to_i #same hour (03 converts to 3)

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

    else

      return false
    
    end#end weekday/first time

  end#end sendStory?

  # returns a cleaned version of the current system time in 24 hour version
  def self.cleanSysTime

    currTime = Time.new

    hours = currTime.hour
    min = currTime.min

    # check if min is single digit
    if min < 10
      min = min.to_s
      min = "0"+min #add zero infront 
    end

    # check if hour is single digit
    if hours < 10
    	hours = hours.to_s
    	hours = "0" + hours #add zero to front
    end

    	cleanedTime = hours.to_s+":"+min.to_s 


    return cleanedTime
  end

  # converts pm/am time into 24hour time 
  def self.convertTimeTo24(oldTime)


    len = oldTime.length
    hoursEndIndex = oldTime.index(':')
    
    hours = oldTime[0,hoursEndIndex]

    colonAndMinutes = oldTime[hoursEndIndex, 3] # [startIndex, length of substring]
      cleanedTime= hours + colonAndMinutes



    if oldTime[len-2,2] == "pm" && hours != "12" #if pm, add 12 to hours (unless noon)     

      hours = (hours.to_i + 12).to_s 
      cleanedTime = hours + colonAndMinutes

    elsif oldTime[len-2,2] == "pm" && hours == "12"

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






  


  

