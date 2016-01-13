#  workers/main_worker.rb                     Phil Esterman     
# 
#  Checks who's set for a story, then calls job to send it.
#  --------------------------------------------------------

#########  DEPENDENCIES  #########

# DB. 
require 'sinatra/activerecord'
require_relative '../models/user'

# Background jobs and recurrence.
require 'sidekiq'
require 'sidetiq'

# Texting API
require 'twilio-ruby'
# Wrapper for texting API
require_relative '../helpers/sprint_helper'
require_relative '../helpers/twilio_helper'

# Stories. 
require_relative '../stories/story'
require_relative '../stories/storySeries'

# Background Jobs for sending stories
require_relative './next_message_worker'
require_relative './new_text_worker'

# Translations
require 'sinatra/r18n'

# Time, transformations
require 'time'
require 'active_support/all'
require_relative '../lib/set_time'


# Email, to learn of failures.
require 'pony'
require_relative '../config/pony'

# Experiment reporting.
require_relative '../experiment/report'

require_relative '../app/series_choice'


##
# Checks who's set for a story, then calls
# job to send it. Asynchronous. 
class MainWorker

  include Sidekiq::Worker
  include Sidetiq::Schedulable
  
  # Configure background job options.
  sidekiq_options :queue => :default
  sidekiq_options retry: false # If it fails, don't resend.
                               # (May lead to many texts.)
  # Run every 2 minutes.                             
  recurrence { hourly.minute_of_hour(0, 2, 4, 6, 8, 10,
                    12, 14, 16, 18, 20, 22, 24, 26, 28, 30,
                    32, 34, 36, 38, 40, 42, 44, 46, 48, 50,
                    52, 54, 56, 58) }
  # Set explicitly because of ice-cube sluggishness.

  # Send to us daily. 
  TESTERS = ["+15612125831"]

  # Environment.
  MODE = ENV['RACK_ENV']
  PRO ||= 'production'
  TEST ||= 'test'

  # Sidekiq syntax:
  # Called as 'perform_async' to run asynchrnously.
  def perform(*args)

    # Send experiment report if ready.
    check_reports

    ### TO REFACTOR ##############################
    @@times = []

    @@user_num_story = 1 #reset for each call
                   #start with the first user.
                   #this is used for computing getWait (updated for each STORY)

    @@user_num_text = 0 #this is used for computing getWait (updated for each TEXT)

      #record this before diving into sending each user a message.
      #the delay is long and thus it might be 5:33 before some users are checked. 
    @@time_now = Time.now.utc
    ### END TO REFACTOR ###########################


    #Remember all the people who have quit! 
    quitters = Array.new 


    if MODE == PRO
      puts "\nCurrent Time: #{Time.now.utc.to_s(:time)} UTC"
      puts "\nSend story?: \n"
    end

    # Send message to 1) subscribed 2) who are ready for story. 
    User.where(subscribed: true).find_each do |user|

      ## LEGACY TEST:
      # Give a Time!
      if user.time == nil && MODE == TEST
        user.update(time: DEFAULT_TIME)
      end
  
      if MODE == PRO
        print "#{user.phone}, time #{user.time.to_s(:time)}:"
        if MainWorker.send_story?(user.phone)
          puts 'YES!!'
        else
          puts 'No.'
        end
      end

        if MainWorker.send_story?(user.phone) 

          # BREAK
          if user.on_break
            if user.days_left_on_break > 1 
              user.update(days_left_on_break: user.days_left_on_break - 1)
            else 
              user.update(days_left_on_break: 0) #remembers that just finished break last time.
              user.update(on_break: false)
            end

          else

            ## LEGACY: 
            # Set default locale.
            if user.locale == nil 
              user.update(locale: 'en')
            end
            # Set this thread's locale as user's locale.
            i18n = R18n::I18n.new(user.locale, ::R18n.default_places)
            R18n.thread_set(i18n)


            #just finished break last time -> include note.
            if user.days_left_on_break == 0 
              note = Text::END_BREAK #note to append
              user.update(days_left_on_break: nil) #set back to normal
            else
              note = ''
            end


           #Should the user be asked to choose a series?
            # If it's:
            # a) not awaiting chioce
            # b) their third story, or every third one thereafter.
            # c) they're not in the middle of a series
            if user.awaiting_choice == false &&
                 series_choice_time?(user.story_number) && 
                 user.next_index_in_series == nil

                 series_choice_choose(user.id, note)

            # First No response to series choice.
            # -> Remind them  
            elsif user.awaiting_choice == true &&
                  user.next_index_in_series == 0 
                 
                 series_choice_remind(user.id, note)

            # Second no response to series choice.
            # -> Drop and notify them.  
            elsif user.next_index_in_series == 999
                
                 series_choice_drop(user.id, note)
                 quitters.push user.phone

            # send STORY or SERIES, but not if awaiting series response
            elsif (user.series_choice == nil && user.next_index_in_series == nil) || user.series_choice != nil

                 Story.send_story(user.id, note)

            end

          end #non-break user

        end#end send_story? large


    end #User.do

    if MODE == PRO
      puts "Just checked :)" + "\n\n" 
    end
    
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


  ### TO REFACTOR ##############################

  # Get and update wait. For sending Stories AND Texts (choose your story, notify lateness, etc.)
  # Ensures that no more than one message per second is sent.
  def self.getWait(type)

      
      total_first_msgs = @@user_num_story + @@user_num_text

      wait = total_first_msgs + (((total_first_msgs - 1) / TwilioHelper::MMS_WAIT) * (TwilioHelper::MMS_WAIT * 2))

    #increments by one each user.
    #jumps 40 seconds each 20 users. 
    if type == NewTextWorker::STORY
      @@user_num_story += 1
    elsif type == NewTextWorker::NOT_STORY
      @@user_num_text += 1 
    end      

    return wait

  end

  def self.test_push_wait(time) 
    @@times.push time 
  end

  def self.test_get_wait_times()
    return @@times
  end
  ### END TO REFACTOR ###########################



  ##
  # Checks whether it's time for a series
  # choice. 
  #  
  # Their third story, or every third one thereafter.
  def series_choice_time?(story_number)
       story_number == 1 || 
      (story_number != 0 && 
       story_number % 3 == 0)
  end


  ##
  # Check if a weekday is valid for a given 
  # schedule of stories per week. 
  #
  def self.valid_weekday?(wday_num, days_per_week)
    # Get valid weekdays
    case days_per_week
    when 3
      wdays = [1, 3, 5]
    when nil, 2
      wdays = [2, 4]
    when 1  
      wdays = [3]
    else
      $stderr.puts "ERROR: #{days_per_week} is an invalid days_per_week."
    end

    # Is this weekday valid for the given schedule? 
    return wdays.include?(wday_num)
  end

  ##
  # Check if the user's time in the next or previous 1 minute? 
  #       
  def self.valid_time(user_time, time_now)
    # Use seconds_since_midnight to compare hour:min, not dates.

    (user_time.seconds_since_midnight - time_now.seconds_since_midnight >= 0 &&
     user_time.seconds_since_midnight - time_now.seconds_since_midnight < 1.minutes) ||
    (time_now.seconds_since_midnight - user_time.seconds_since_midnight >= 0 &&
     time_now.seconds_since_midnight - user_time.seconds_since_midnight < 1.minutes)
  end

  ##
  # Check if the user should receive a story now. 
  # Time variable allows for testing, sending time.
  def self.send_story?(user_phone, *time) 
    user = User.find_by(phone: user_phone)

    # Allow to manual set time in testing.
    if time.empty? == false &&
        MODE == TEST

      @@time_now = time.first
    end

   # They're a candidate if it's us, or 
   # - it's the right weekday
   # - they didn't enroll in the last day.
    if TESTERS.include?(user.phone) ||
         (MainWorker.valid_weekday?(@@time_now.wday, user.days_per_week) &&
         (@@time_now - 1.day) > user.created_at)


       # Is their time in the next or previous 1 minute? 
       # Use seconds_since_midnight to compare hour:min, not dates.       
       if MainWorker.valid_time(user.time, @@time_now) 
            return true
       end

    end
    return false
  end


end  #end class
