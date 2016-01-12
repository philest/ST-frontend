require 'rubygems'
require 'bundler/setup'

require 'twilio-ruby'
require 'sinatra/activerecord'
require_relative '../models/user'           #add the user model
require 'sidekiq'
require 'sidetiq'

require 'sinatra/r18n'

require 'time'
require 'active_support/all'

require_relative '../helpers/sprint_helper'
require_relative '../stories/story'
require_relative '../stories/storySeries'
require_relative '../helpers/twilio_helper'
require_relative './next_message_worker'
require_relative './new_text_worker'

require_relative '../lib/set_time'

#email, to learn of failurs
require 'pony'
require_relative '../config/pony'

require_relative '../models/experiment'
require_relative '../experiment/send_report'

class MainWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable
  
  sidekiq_options :queue => :default

  MAX_TEXT = 155 #leaves room for (1/6) at start (160 char msg)
  
  TIME_SMS_NORMAL = "StoryTime: Hey there! We want to make StoryTime better for you. When do you want to receive stories (e.g. 5:00pm)?

  Rememeber screentime within 2hrs before bedtime can delay children's sleep and carry health risks, so please read earlier."

  TIME_SMS_SPRINT_1 = "(1/2)\nStoryTime: Hi! We want to make StoryTime better for you. When do you want to receive stories (e.g. 5:00pm)?"

  TIME_SMS_SPRINT_2 = "(2/2)\nRememeber screentime within 2hrs before bedtime can delay children's sleep and carry health risks, so please read earlier."

  BIRTHDATE_UPDATE = "StoryTime: If you want the best stories for your child's age, reply with your child's birthdate in MMYY format (e.g. 0912 for September 2012)."
  
  TESTERS = ["+15612125831", "+15619008225", "+16468878679", "+16509467649", "+19417243442", "+12022518772" ,"+15614796303", "+17722330863", "+12392735883", "+15614796303", "+13522226913", "+1615734535", "+19735448685", "+15133166064", "+18186897323", "+15617083233", "+14847063250", "+18456711380", "+15613056454", "+15618668227", "+15617893548", "+15615422027"]



 #set flags for getWait
 STORY = 1
 TEXT = 2




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

    begin
      #Experiment: Send report if completed-->i.e. past end_date! 
      Experiment.where("active = true").to_a.each do |exper|
        if (exper.end_date && Time.now > exper.end_date)
          send_report(exper.id)
        end
      end
    rescue StandardError => e
        $stderr.print "Experiment report not sent.\n\nError: #{e}"
        $stderr.print  "\n\nBacktrace:\n\n"
        (1..30).each { $stderr.print e.backtrace.shift }
    end


    #logging
    puts "\nSystemTime: " + MainWorker.cleanSysTime + "\n"

    #logging
    puts "\nSend story?: \n"

    @@times = []


    @@user_num_story = 1 #reset for each call
                   #start with the first user.
                   #this is used for computing getWait (updated for each STORY)

    @@user_num_text = 0 #this is used for computing getWait (updated for each TEXT)





      #record this before diving into sending each user a message.
      #the delay is long and thus it might be 5:33 before some users are checked. 
    @@time_now = Time.now.utc

    #Remember all the people who have quit! 
    quitters = Array.new 

    # send Twilio message
    # only for subscribed
    User.where(subscribed: true).find_each do |user|

      
      #LEGACY: set default locale.
      if user.locale == nil 
        user.update(locale: 'en')
      end

      #set this thread's locale as user's locale
      i18n = R18n::I18n.new(user.locale, ::R18n.default_places)
      R18n.thread_set(i18n)


      if user.time && user.time.class != String #LEGACY


        # handling test users: convert give Time!
        if user.time == nil && ENV['RACK_ENV'] == 'test'
          user.update(time: DEFAULT_TIME)
        end


        #logging info
        print  user.phone + " with time " + user.time.hour.to_s + ":" + user.time.min.to_s + "  -> "
        if MainWorker.sendStory?(user.phone)
          puts 'YES!!'
        else
          puts 'No.'
        end


          if MainWorker.sendStory?(user.phone) 



            if user.on_break

              if user.days_left_on_break > 1 
                user.update(days_left_on_break: user.days_left_on_break - 1)
              else 
                user.update(days_left_on_break: 0) #remembers that just finished break last time.
                user.update(on_break: false)
              end

            else

              #just finished break last time -> include note.
              if user.days_left_on_break == 0 
                note = Text::END_BREAK #note to append
                user.update(days_left_on_break: nil) #set back to normal
              else
                note = ''
              end


             #Should the user be asked to choose a series?
              #If it's all of these:
              #0) not awaiting chioce
              #a) their time, 
              #b) their third story, or every third one thereafter.
              #c) they're not in the middle of a series
  

              if user.awaiting_choice == false && ((user.story_number == 1 || (user.story_number != 0 && user.story_number % 3 == 0)) && user.next_index_in_series == nil)

                #get set for first in series
                user.update(next_index_in_series: 0)
                user.update(awaiting_choice: true)
                #choose a series



                myWait = MainWorker.getWait(TEXT)

                NewTextWorker.perform_in(myWait.seconds, note + R18n.t.choice.greet[user.series_number], NewTextWorker::NOT_STORY, user.phone)

              elsif user.awaiting_choice == true && user.next_index_in_series == 0 # the first time they haven't responded
                
                msg = R18n.t.no_reply.day_late + " " + R18n.t.choice.no_greet[user.series_number]

                myWait = MainWorker.getWait(TEXT)
                NewTextWorker.perform_in(myWait.seconds, note + msg, NewTextWorker::NOT_STORY, user.phone)

                user.update(next_index_in_series: 999)  

              elsif user.next_index_in_series == 999 #the second time they haven't responded

                user.update(subscribed: false)
                user.update(awaiting_choice: false)

                quitters.push user.phone

                myWait = MainWorker.getWait(TEXT)
                NewTextWorker.perform_in(myWait.seconds, R18n.t.no_reply.dropped, NewTextWorker::NOT_STORY, user.phone)

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

                    myWait = MainWorker.getWait(TEXT)
                    NewTextWorker.perform_in(myWait.seconds, R18n.t.no_reply.dropped, NewTextWorker::STORY, user.phone)

                else #MULTIMEDIA MESSAGING (MMS)!

                    #start the MMS message stack

                    myWait = MainWorker.getWait(STORY)
                    NextMessageWorker.perform_in(myWait.seconds, note + story.getSMS, story.getMmsArr, user.phone)  

                end#MMS or SMS

              end#end story_subpart

            end #non-break user

          end#end sendStory? large

      end  #LEGACT STRING 

    end #User.do
        
    puts "doing hard work!!" + "\n\n" 

    #email us about the quitters

    if not quitters.empty? and MODE == "production"
      Pony.mail(:to => 'phil.esterman@yale.edu',
            :cc => 'henok.addis@yale.edu',
            :from => 'phil.esterman@yale.edu',
            :subject => 'StoryTime: Users were dropped.',
            :body => "#{quitters.length} users never responeded, so were dropped.

                      Here are the bad guys:
                      #{quitters}")
    end


  end #end perform method



  #gets and updates wait, for sending Stories AND Texts (choose your story, notify lateness, etc.)
  #ensures that no more than one message per second is sent.
  def self.getWait(type)

      
      total_first_msgs = @@user_num_story + @@user_num_text

      wait = total_first_msgs + (((total_first_msgs - 1) / TwilioHelper::MMS_WAIT) * (TwilioHelper::MMS_WAIT * 2))

    #increments by one each user.
    #jumps 40 seconds each 20 users. 
    if type == STORY
      @@user_num_story += 1
    elsif type == TEXT
      @@user_num_text += 1 
    end      

    return wait

  end




  # def self.test_get_wait()

  #     total_first_msgs = @@user_num_story + @@user_num_text

  #     wait = total_first_msgs + (((total_first_msgs - 1) / TwilioHelper::MMS_WAIT) * (TwilioHelper::MMS_WAIT * 2))

  #     return wait
  # end

  def self.test_push_wait(time) 
    @@times.push time 
  end


  def self.test_get_wait_times()
    return @@times
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

    if (valid_weekdays.include?(this_weekday) && (user.created_at <= one_day_age)) || (TESTERS.include?(user.phone))
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




end  #end class
