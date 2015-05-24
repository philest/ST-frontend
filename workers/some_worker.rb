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

@story = [ "StoryTime: Enjoy tonight's story:

  Now We Are Six

  When I was one,
  I had just begun.

  When I was two,
  I was nearly new.

  When I was three,
  I was hardly me.

  When I was four,
  I was not much more.

  When I was five,
  I was just alive.

  But now I am six,
  I'm as clever as clever.
  
  So I think I'll be six
  Now and forever.

  a)Ask your child how old they are and what their birthday is?

  b)Does your child think it’s possible to be 6 years old forever?
  
  c)What is the smallest number your child knows? The biggest? Can your child count all the way to it?",

  "StoryTime: Keep up the great work!

  Unscratchable Itch

  There is a spot that you can’t scratch
  Right between your shoulder blades,
  Like an egg that just won’t hatch
  Here you set and there it stay

  Turn and squirm and try to reach it,
  Twist your neck and bend your back,

  Hear your elbows creak and creak,
  Stretch your fingers, now you bet it’s
  Going to reach –
  
  no that won’t get it-
  Hold your breath and stretch and pray,
  Only just an inch away,

  Worse than a sunbeam you can’t catch
  Is that one spot that
  You can’t scratch.

a)Is there a spot on your back that you can’t reach? Try the other hand! Can you reach your toes…without bending your knees!

b)Reread the first line of the poem. But this time, clap your hands as you say each syllable.
Have your child repeat the line. Help them clap their hands as they say each syllable.

c)Try this for the second line! The poet rhymes the word \"scratch\" with \"hatch.\" Can you think of any other words that rhyme with \"scratch?\" See if you can name 5!",
"StoryTime: Here's tonight's poem:

  Where the Sidewalk Ends

  There is a place where the sidewalk ends
  And before the street begins.
  And there the grass grows soft and white.
  And there the sun burns crimson bright
  And there the moon-bird rests from his flight
  To cool in the peppermint wind.

  Let us leave this place where the smoke blows black
  And the dark street winds and bends.
  Past the pits where the asphalt flowers grow
  We shall walk with a walk that is measured and slow,
  And watch where the chalk-white arrows go
  To the place where the sidewalk ends.

  Yes we'll walk with a walk that is measured and slow,
  And we'll go where the chalk-white arrows go,
  For the children, they mark, and the children,they know
  The place where the sidewalk ends.

a) Have you ever been to the end of the sidewalk? Would you want to go? What do you think it looks like there?

b) Reread the third line. Ask your child to repeat it. Try to think of 10 other words that start with the letter “g”! 
Can you make the shape of the letter “g” with your fingers? How about with your body?"]

  MAX_TEXT = 155 #leaves room for (1/6) at start (160 char msg)
	
	sidekiq_options retry: false #if fails, don't resent (multiple texts)


  recurrence { hourly.minute_of_hour(0, 2, 4, 6, 8, 10,
  									12, 14, 16, 18, 20, 22, 24, 26, 28, 30,
  									32, 34, 36, 38, 40, 42, 44, 46, 48, 50,
  									52, 54, 56, 58) } #set explicitly because of ice-cube sluggishness

  def perform(*args)
    
    account_sid = ENV['TW_ACCOUNT_SID']
    auth_token = ENV['TW_AUTH_TOKEN']

  	@client = Twilio::REST::Client.new account_sid, auth_token


    puts "SystemTime is: " + SomeWorker.cleanSysTime

  	# send Twilio message
    User.all.each do |user|

      #logging info
      print 'Send story to time ' +SomeWorker.convertTimeTo24(user.time)+"?: "
      if SomeWorker.sendStory?(user)
        puts 'YES!!'
      else
         puts 'No.'
      end

    	
      if user.carrier != "Sprint Spectrum, L.P."


        if SomeWorker.sendStory?(user) 
      		message = @client.account.messages.create(:body => 
      		"StoryTime: the timed job worked!!",
      	    :to => user.phone,     # Replace with your phone number
      	    :from => "+17377778679")   # Replace with your Twilio number

          puts "Sent message to" + user.phone + "\n\n"

        end

      else #sprint phone
      
        if SomeWorker.sendStory?(user) 

          smsArr = SomeWorker.sprint(@story[0])

          smsArr.each_with_index do |text, index|
            message = @client.account.messages.create(
              :body => text,
              :to => user.phone,     # Replace with your phone number
              :from => "+17377778679")   # Replace with your Twilio number

            puts "Sent message part #{index} to" + user.phone + "\n\n"
          end
        end


      end

    end

    puts "doing hard work!!" + "\n\n" 



  end

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

          binding.pry

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





  # helper methods

  # check if user's story time is in the next two minutes
  def self.sendStory?(user) #don't know object as parameter

    currTime = SomeWorker.cleanSysTime
    userTime = SomeWorker.convertTimeTo24(user.time)

    currHour = currTime[0,2]   
    userHour = userTime[0,2]

    #CONVERTING FROM EASTERN TO UTC when not my machine!!!!
    if ENV['MY_MACHINE'] != "true"
    userHour = (userTime[0,2].to_i + 4).to_s
    end


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






  


  

