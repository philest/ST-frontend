#  helpers/twilio_helper.rb                   Phil Esterman     
# 
#  Helpers for Twilio messaging and testing.   
#  --------------------------------------------------------


require 'sinatra/r18n'
require 'twilio-ruby'
require_relative '../workers/new_text_worker'

#set Twilio credentials:
account_sid = ENV['TW_ACCOUNT_SID']
auth_token = ENV['TW_AUTH_TOKEN']

@client = Twilio::REST::Client.new account_sid, auth_token

##
# Helpers for Twilio messaging and testing.   
class TwilioHelper

## Environments
PRO ||= "production"
TEST ||="test"
# Run tests with Twilio test credentials. 
TEST_CRED = "test_cred"
# Current environment. 
@@mode = ENV['RACK_ENV']


# To know how long to wait between messages.
LAST = "last"
NORMAL = "normal"
NO_WAIT = "no wait"

# Wait times for SMS and MMS between the *same* user.
SMS_WAIT = 12
MMS_WAIT = 20

# The wait between *different* users. 
LAST_WAIT = 1


MMS = "MMS"
SMS = "SMS"

### Testing Wrapper for Twilio
  
  # Refresh the testing inbox for SMS and MMS
  def self.initialize_testing_vars
    @@twiml_sms = Array.new
    @@twiml_mms = Array.new
    @@twiml = ""
  end

  # Return a string of the last SMS sent. 
  def self.getSimpleSMS
    return @@twiml
  end

  # Return an array of all the SMS sent.
  def self.getSMSarr
    return @@twiml_sms
  end

  # Return an array of all the MMS sent.
  def self.getMMSarr
    return @@twiml_mms
  end

  # Configure and turn on test credentials
  # for higher-fidelity testing. 
  def self.testCred 
      account_sid = ENV['TEST_TW_ACCOUNT_SID']
      auth_token = ENV['TEST_TW_AUTH_TOKEN']

      @client = Twilio::REST::Client.new account_sid, auth_token

      @@my_twilio_number = "+15005550006"
      @@mode = TEST_CRED
  end

  # Turn off test credentials.
  def self.testCredOff
    @@mode = ENV['RACK_ENV']
  end

  if ENV['RACK_ENV'] == PRO
    @@my_twilio_number = "+12032023505"       
  elsif ENV['RACK_ENV'] == TEST   #test credentials for integration from SMS.
    TwilioHelper.initialize_testing_vars
  end



### Twilio Messaging Helpers
  
  ##
  # Wrapper for SMS reply that diverts to testing
  # or Twilio. 
  def self.smsRespond(body, order)

      if @@mode == TEST
        @@twiml = body
        @@twiml_sms.push body

      elsif @@mode == PRO || @@mode == TEST_CRED
        
        TwilioHelper.smsRespondHelper(body)
      end

  end

  ##
  # Wrapper for MMS reply that diverts to testing
  # or Twilio. 
  def self.mmsRespond(mms_url)

    if @@mode == TEST || @@mode == TEST_CRED
      @@twiml_mms.push mms_url
    elsif @@mode == PRO
      TwilioHelper.mmsRespondHelper(mms_url)
    end

  end

  ##
  # Wrapper for SMS and MMS reply that diverts to
  # testing or Twilio. 
  def self.fullRespond(body, mms_url, order)

    if mms_url.class == Array
      mms_url = mms_url.shift
    end

    if @@mode == TEST || @@mode == TEST_CRED
     @@twiml_mms.push mms_url
     @@twiml_sms.push body
    elsif @@mode == PRO
      TwilioHelper.fullRespondHelper(body, mms_url)
    end

  end


  ##
  # Wrapper for new SMS sending (to testing or Twilio)
  def self.smsSend(body, user_phone)
    if @@mode == TEST || @@mode == TEST_CRED
      @@twiml = body
      @@twiml_sms.push body

      #turn on testcred
      TwilioHelper.testCred
    end
      #for Test_Cred: simulate actual REST api
      TwilioHelper.smsSendHelper(body, user_phone)
  end

  ##
  # Wrapper for new MMS sending (to testing or Twilio)
  def self.mmsSend(mms_url, user_phone)
    if @@mode == TEST || @@mode == TEST_CRED
      @@twiml_mms.push mms_url
      puts "Sent #{mms_url[-10..-5]}"
    elsif @@mode == PRO
      TwilioHelper.mmsSendHelper(mms_url, user_phone)
    end
  end

  ##
  # Wrapper for new SMS + MMS sending (to testing or Twilio)
  def self.fullSend(body, mms_url, user_phone, order)
  #account for mms_url in arrays
    if mms_url.class == Array
      mms_url = mms_url[0]
    end
  
    TwilioHelper.fullSendHelper(body, mms_url, user_phone)
  end


  ### TWILIO RESPONSES

  ##
  # Twilio SMS response.
  def self.smsRespondHelper(body)
      twiml = Twilio::TwiML::Response.new do |r|
          r.Message body #SEND Text::SPRINT MSG
        end
        twiml.text
  end

  ##
  # Twilio MMS response.
  def self.mmsRespondHelper(mms_url)
      twiml = Twilio::TwiML::Response.new do |r|
        r.Message do |m|
          m.Media mms_url
        end
      end
      twiml.text
  end

  ##
  # Twilio joint SMS - MMS response.
  def self.fullRespondHelper(body, mms_url)
      twiml = Twilio::TwiML::Response.new do |r|
        r.Message do |m|
          m.Media mms_url
          m.Body body
        end
      end
      twiml.text
  end

  ### TWILIO NEW SENDING

  ##
  # Twilio send new SMS. 
  def self.smsSendHelper(body, user_phone)

    if @@mode == PRO
        account_sid = ENV['TW_ACCOUNT_SID']
        auth_token = ENV['TW_AUTH_TOKEN']
      @client = Twilio::REST::Client.new account_sid, auth_token
    end

    @client.account.messages.create(
      :body => body,
      :to => user_phone,     # Replace with your phone number
      :from => @@my_twilio_number)   # Replace with your Twilio number

    if @@mode == TEST_CRED 
      puts "TC: Sent sms to #{user_phone}: #{body[10, 18]}" 
    else
      puts "Sent sms to #{user_phone}: #{body[10, 18]}"
    end 
    
    #turn off testCred
    TwilioHelper.testCredOff
  end

  ##
  # Twilio send new MMS. 
  def self.mmsSendHelper(mms_url, user_phone)
      
    if @@mode == PRO
        account_sid = ENV['TW_ACCOUNT_SID']
        auth_token = ENV['TW_AUTH_TOKEN']
      @client = Twilio::REST::Client.new account_sid, auth_token
    end

    @client.account.messages.create(
      :media_url => mms_url,
      :to => user_phone,     # Replace with your phone number
      :from => @@my_twilio_number)   # Replace with your Twilio number

    puts "Sent mms to #{user_phone}: #{mms_url[-10..-5]}"
  end

  ##
  # Twilio send new joint SMS - MMS. 
  def self.fullSendHelper(body, mms_url, user_phone)
  
    if @@mode == PRO
        account_sid = ENV['TW_ACCOUNT_SID']
        auth_token = ENV['TW_AUTH_TOKEN']
      @client = Twilio::REST::Client.new account_sid, auth_token
    end
          
    #get user
    @user = User.find_by_phone(user_phone)

    #chop up if a long message to a sprint user.
    if body.length >= 160 && @user.carrier == Text::SPRINT 
        
      sprint_arr = Sprint.chop(body)

      if @@mode == TEST ||
           @@mode == TEST_CRED
        @@twiml_mms.push mms_url
        @@twiml_sms.push sprint_arr.shift #add first part
      else

      #send mms with first part of sms series
      @client.account.messages.create(
            :media_url => mms_url,
            :body => sprint_arr.shift,
            :to => user_phone,    
            :from => @@my_twilio_number)

      end 

      puts "Sent #{mms_url[-10..-5]} and sms part 1"

      #send the rest of sms series
            NewTextWorker.perform_in(MMS_WAIT.seconds, sprint_arr, NewTextWorker::NOT_STORY, user_phone)

        else #not long-sprint

      if @@mode == TEST || @@mode == TEST_CRED
        @@twiml_mms.push mms_url
        @@twiml_sms.push body
        puts "Sent #{mms_url[-10..-5]}, #{body}"

          else
             message = @client.account.messages.create(
              :body => body,
              :media_url => mms_url,
              :to => user_phone,     # Replace with your phone number
              :from => @@my_twilio_number)   # Replace with your Twilio number
      end

    end

        puts "Sent mms to #{user_phone}: #{mms_url[-10..-5]}"
      puts "along with sms: #{body[10, 18]}" 

    end






  ### the API for Response and New Sending

  ### RESPONSE API

  ##
  # API to respond with a joint SMS - MMS
  def self.text_and_mms(body, mms_url, user_phone)

    @user = User.find_by(phone: user_phone)

    if @user == nil
        puts "Sent full to new user"
      else
      puts "Sent full to #{@user.phone}}" 
      end

      TwilioHelper.fullRespond(body, mms_url, LAST)
    end

  ##
  # API to respond with a MMS
  def self.mms(mms, user_phone)
       
    
    if (user = User.find_by(phone: user_phone)) == nil
        puts "Sent mms to new user"
      else
        puts "Sent to #{user.phone}: #{mms[-10..-5]}" 
      end


      TwilioHelper.mmsRespond(mms)

  end

  ##
  # API to respond with an SMS
  def self.text(normalSMS, sprintSMS, user_phone)
  
    @user = User.find_by(phone: user_phone)

    #if sprint
    if (@user == nil || @user.carrier == Text::SPRINT) &&
        sprintSMS.length > 160

      sprintArr = Sprint.chop(sprintSMS)
      msg = sprintArr.shift # pop off first element
                  # and send as immediate reply.

      # Send all but first SMS asynchronously. 
      NewTextWorker.perform_in(14.seconds,
                     sprintArr,
                     NewTextWorker::NOT_STORY,
                     @user.phone)

    elsif @user == nil || @user.carrier == Text::SPRINT
      msg = sprintSMS 
    else
      msg = normalSMS
    end

    if (@@mode == TEST || @@mode == TEST_CRED) && ((@user == nil || @user.carrier == Text::SPRINT) && sprintSMS.length > 160)
      NewTextWorker.drain
    end

    if @user == nil
        puts "Sent full to new user"
      else
      puts "Sent sms to #{@user.phone}: " + "\"" + msg[10,18] + "...\""
      end
    
    TwilioHelper.smsRespond(msg, LAST)

  end  





  ### NEW SENDING--- Not a response.  

  # Send new Sprint texts (asynchonously).
  def self.new_sprint_long_sms(long_sms, user_phone)
    @user = User.find_by(phone: user_phone)

    #find if it's first story or not
    if @user.total_messages < 1
      type = NewTextWorker::STORY
    else
      type = NewTextWorker::NOT_STORY
    end

    NewTextWorker.perform_async(long_sms, type, user_phone)
  end

  # Send new MMS (async).
  def self.new_mms(sms, mms_array, user_phone)
    @user = User.find_by(phone: user_phone)

    ##account for single mms as string
    if mms_array.class == String
      mms_array = [mms_array]
    end

    #if long sprint mms + sms, send all images, then texts one-by-one
    if @user != nil && (@user.carrier == Text::SPRINT && sms.length > 160)

      mms_array.each_with_index do |mms_url, index|
          
          TwilioHelper.mmsSend(mms_url, user_phone)
             #for all, because text follows
      end

      TwilioHelper.new_sprint_long_sms(sms, user_phone)

    else

      mms_array.each_with_index do |mms, index|

        if index + 1 == mms_array.length #last image comes w/ SMS
        
          TwilioHelper.fullSend(sms, mms, user_phone, LAST)

        else

          TwilioHelper.mmsSend(mms, user_phone)

        end

      end

    end

  end


  # Send new SMS (async).
  def self.new_text(normalSMS, sprintSMS, user_phone)
    
    @user = User.find_by(phone: user_phone)

    #if sprint
    if (@user == nil || @user.carrier == Text::SPRINT) && sprintSMS.length > 160

      TwilioHelper.new_sprint_long_sms(sprintSMS, user_phone)
    
    else

      if @user == nil || @user.carrier == Text::SPRINT
        msg = sprintSMS 
      else #not Sprint
        msg = normalSMS 
      end 

      TwilioHelper.smsSend(msg, user_phone)

    end

  end  

  # Sends a new text without sleeping. Relies on background worker's 
  # async call. 
  # 
  # Used in NewTextWorker...
  def self.new_text_no_wait(normalSMS, sprintSMS, user_phone)
    
    @user = User.find_by(phone: user_phone)

    #if sprint
    if (@user == nil || @user.carrier == Text::SPRINT) && sprintSMS.length > 160

      TwilioHelper.new_sprint_long_sms(sprintSMS, user_phone)

    else

      if @user == nil || @user.carrier == Text::SPRINT
        msg = sprintSMS 
      else #not Sprint
        msg = normalSMS 
      end 

      TwilioHelper.smsSend(msg, user_phone)

    end

  end  


end

