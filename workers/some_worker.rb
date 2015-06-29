# require '.config/environments'
require 'rubygems'
require 'twilio-ruby'
require 'sinatra/activerecord'
require_relative '../models/user'           #add the user model
require 'sidekiq'
require 'sidetiq'

require 'time'
require 'active_support/all'

require_relative '../sprint'
require_relative '../message'
require_relative '../messageSeries'
require_relative '../helpers'
require_relative './next_message_worker'


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

  DAY_LATE = "StoryTime: Hi! We noticed you didn't choose your last story."

  
  DROPPED = "We haven't heard from you, so we'll stop sending you messages. To get StoryTime again, reply with STORY"

  SERIES_CHOICES = ["StoryTime: Hi! You can now choose new stories. Do you want stories about Marley the puppy or about Bruce the moose?\n\nReply \"p\" for puppy or \"m\" for moose."]

  NO_GREET_CHOICES = ["Do you want stories about Marley the puppy or about Bruce the moose?\n\nReply \"p\" for puppy or \"m\" for moose."]

  TESTERS = ["+15612125831", "+15619008225", "+16468878679", "+16509467649", "+19417243442", "+12022518772" ,"+15614796303", "+17722330863", "+12392735883", "+15614796303", "+13522226913", "+1615734535", "+19735448685", "+15133166064", "+18186897323", "+15617083233", "+14847063250", "+18456711380", "+15613056454", "+15618668227", "+15617893548", "+15615422027"]


  DEFAULT_TIME = Time.new(2015, 6, 21, 17, 30, 0, "-04:00").utc #Default Time: 17:30:00 (5:30PM), EST


  MODE = ENV['RACK_ENV']


  #time for the birthdate and time updates: NOTE, EST set.  
  if ENV['RACK_ENV'] == "production"
    UPDATE_TIME = "20:00"
    UPDATE_TIME_2 = "20:00"
  else
    UPDATE_TIME = "16:00"
    UPDATE_TIME_2 = "16:01"
  end





	sidekiq_options retry: false #if fails, don't resent (multiple texts)


  recurrence { hourly.minute_of_hour(0, 2, 4, 6, 8, 10,
  									12, 14, 16, 18, 20, 22, 24, 26, 28, 30,
  									32, 34, 36, 38, 40, 42, 44, 46, 48, 50,
  									52, 54, 56, 58) } #set explicitly because of ice-cube sluggishness





  def perform(*args)

    account_sid = ENV['TW_ACCOUNT_SID']
    auth_token = ENV['TW_AUTH_TOKEN']

    @client = Twilio::REST::Client.new account_sid, auth_token

    #logging
    puts "\nSystemTime: " + SomeWorker.cleanSysTime + "\n"

    #logging
    puts "\nSend story?: \n"



    @@user_num = 1 #reset for each call
                   #start with the first user.
                   #this is used for computing getWait




      #record this before diving into sending each user a message.
      #the delay is long and thus it might be 5:33 before some users are checked. 
    @@time_now = Time.now.utc





    # send Twilio message
    # only for subscribed
    User.where(subscribed: true).find_each do |user|

  if user.time.class != String #LEGACY


      #handling old users: convert give Time!
      if user.time == nil || user.id < 140
        user.update(time: DEFAULT_TIME)
      end



      #logging info
      print  user.phone + " with time " + user.time.hour.to_s + ":" + user.time.min.to_s + "  -> "
      if SomeWorker.sendStory?(user.phone)
        puts 'YES!!'
      else
        puts 'No.'
      end

      #UPDATE time


      #UPDATE Birthdate! 
      # if user.set_birthdate == false && (SomeWorker.cleanSysTime == UPDATE_TIME || SomeWorker.cleanSysTime == UPDATE_TIME_2) && user.total_messages == 5 #Customize time 

      #   user.update(set_birthdate: true)

      #   Helpers.new_text(mode, BIRTHDATE_UPDATE, BIRTHDATE_UPDATE, user.phone)
        
      # end

        if SomeWorker.sendStory?(user.phone) 


         #Should the user be asked to choose a series?
          #If it's all of these:
          #0) not awaiting chioce
          #a) their time, 
          #b) their third story, or every third one thereafter.
          #c) they're not in the middle of a series
          # require 'pry'
          # binding.pry


          if user.awaiting_choice == false && ((user.story_number == 1 || (user.story_number != 0 && (user.story_number + 1) % 3 == 0)) && user.next_index_in_series == nil)

            #get set for first in series
            user.update(next_index_in_series: 0)
            user.update(awaiting_choice: true)
            #choose a series

            Helpers.new_text(SERIES_CHOICES[user.series_number], SERIES_CHOICES[user.series_number], user.phone)

          elsif user.awaiting_choice == true && user.next_index_in_series == 0 # the first time they haven't responded
            
            msg = DAY_LATE + " " + SomeWorker::NO_GREET_CHOICES[user.series_number]

            Helpers.new_text(msg, msg, user.phone)
            user.update(next_index_in_series: 999)  

          elsif user.next_index_in_series == 999 #the second time they haven't responded

             user.update(subscribed: false)
             user.update(awaiting_choice: false)
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

                #start the MMS message stack

                myWait = SomeWorker.getWait()
                NextMessageWorker.perform_in(myWait.seconds , story.getSMS, story.getMmsArr, user.phone)  

            end#MMS or SMS

          end#end story_subpart

        end#end sendStory? large

    end#end User.do

  end#LEGACY STRING
        
    puts "doing hard work!!" + "\n\n" 

  end #end perform method



  def self.getWait()
    wait = @@user_num + (( (@@user_num - 1) / Helpers::MMS_WAIT) * (Helpers::MMS_WAIT * 2))
    #increments by one each user.
    #jumps 40 seconds each 20 users. 
    @@user_num += 1

    return wait
  end






  # helper methods
  # check if user's story time is this exact minute, or the next minute
  def self.sendStory?(user_phone, *time) #don't know object as parameter  #time variable allows for testing, sending time.

    user = User.find_by(phone: user_phone)

    if time[0] != nil && MODE == "test"
      @@time_now = time[0]
    end



    this_weekday = @@time_now.wday 

    one_day_age = @@time_now - 1.day

    case user.days_per_week
      when 3
        valid_weekdays = [1, 3, 5]
      when nil, 2
        valid_weekdays = [2, 4]
      when 1  
        valid_weekdays = [3]
      else
       puts "ERR: invalid days of week"
    end

    if (valid_weekdays.include?(this_weekday) && (user.created_at <= one_day_age)) || TESTERS.include?(user.phone)
                                                                     #SEND TO US EVERYDAY
                                                                     #SEND IF ony valid day and NOT created this past day!
                                                                    #Note: this messes up if they created this past 5:30pm on a M or W
      currHour = @@time_now.hour
      userHour = user.time.utc.hour 

      currMin =  @@time_now.min
      userMin = user.time.utc.min

      if currHour == userHour
        
        if (userMin - currMin) < 2 && (userMin - currMin) >= 0 #if either now, or next minute
          return true
        else
          return false
        end

      elsif currHour == userHour && (currMin == 59 && userMin == 1) #edge case
      
        return true
      
      else
      
        return false
      
      end#end currHour == userHour

    else

      return false
    
    end#end ifvalid days
    
  end#end sendStory?



  # returns a cleaned version of the current system time in 24 hour version
  #ALWAYS IN UTC
  def self.cleanSysTime 

    currTime = Time.now

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




end  
