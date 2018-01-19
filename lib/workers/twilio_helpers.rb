 require 'pony'
require_relative '../../config/pony.rb'


module TwilioTextingHelpers
  # let's run these as class methods as well
  def self.included base
    base.extend self
  end

  # our twilio number
  STORYTIME_NO     = ENV['ST_MAIN_NO']
  USER_REPLIES_NO  = ENV['ST_USER_REPLIES_NO']

  puts 'STORYTIME_NO is #{STORYTIME_NO}'

  DEMO_NO = "+12033035711"
  # Sprint name, from Twilio_Lookups url. 
  SPRINT = "Sprint Spectrum, L.P."
  ATT = "AT&T Wireless"
  T_MOBILE = "T-Mobile USA, Inc."

  SMS = 'SMS'
  MMS = 'MMS'

  # Sleep to have two SMS deliver in order
  SMS_SLEEP = 12
  MMS_SLEEP = 20

  # Wrappers for Twilio calls.
  def send_sms(body, to_phone, from_phone, sequence_params={})
    client = Twilio::REST::Client.new ENV['TW_ACCOUNT_SID'], ENV['TW_AUTH_TOKEN']

    script        = sequence_params['script']
    sequence      = sequence_params['sequence']
    last_sequence = sequence_params['last_sequence']

    if script and sequence and last_sequence
      # idea: put a retry index in the callback_query, which increments each time we retry
      callback_query = "?phone=#{to_phone}&script=#{script}&next_sequence=#{sequence}&last_sequence=#{last_sequence}"

      res = client.account.messages.create(
        :body => body,
        :to => to_phone,     
        :from => from_phone,
        # TODO: add this to .env for local and Heroku environment for production
        :StatusCallback => ENV['TW_CALLBACK_URL'] + callback_query
      )
    else # send plain sms, no callback por favor
       res = client.account.messages.create(
        :body => body,
        :to => to_phone,     
        :from => from_phone,
      )
    end

    puts "Sent SMS to #{to_phone}. Body: \"#{body}\"" 
    return res 

    # TODO: collect error_code and status information and react accordingly.
  end

  def send_mms(media_url, to_phone, from_phone, sequence_params={})
    client = Twilio::REST::Client.new ENV['TW_ACCOUNT_SID'], ENV['TW_AUTH_TOKEN']

    script        = sequence_params['script']
    sequence      = sequence_params['sequence']
    last_sequence = sequence_params['last_sequence']

    if script and sequence and last_sequence
      callback_query = "?phone=#{to_phone}&script=#{script}&next_sequence=#{sequence}&last_sequence=#{last_sequence}"
      
      res = client.account.messages.create(
        :media_url => media_url,
        :to => to_phone,     
        :from => from_phone,
        :StatusCallback => ENV['TW_CALLBACK_URL'] + callback_query
      )
    else # send plain mms, no callback por favor
      res = client.account.messages.create(
        :media_url => media_url,
        :to => to_phone,     
        :from => from_phone,
      )
    end
    puts "Sent MMS to #{to_phone}. Image: \"#{media_url}\""   

    return res

    # TODO: collect error_code and status information and react accordingly.  
  end

  # TODO: DO THE SAME FOR SEND_JOINT AS YOU DID FOR SEND_SMS AND SEND_MMS
  def send_joint(media_url, body, to_phone, from_phone)
    client = Twilio::REST::Client.new ENV['TW_ACCOUNT_SID'], ENV['TW_AUTH_TOKEN']
    client.account.messages.create(
      :media_url => media_url,
      :body => body,
      :to => to_phone,     
      :from => from_phone
    )

    puts "Sent MMS and SMS to #{to_phone}."     
  end 

  def reply_joint(media_url, body)
    puts "Replied MMS and SMS."
    twiml = Twilio::TwiML::Response.new do |r|
      r.Message do |m|
        m.Media media_url
        m.Body body
      end
    end
    twiml.text
  end

  def reply_sms(body)
    puts "Replied MMS and SMS."
    twiml = Twilio::TwiML::Response.new do |r|
      r.Message body
    end
    twiml.text
  end

  def get_carrier(phone)
    # Get the user's phone carrier. 
    @lookups_client = Twilio::REST::LookupsClient.new ENV["TW_ACCOUNT_SID"], ENV["TW_AUTH_TOKEN"]
    twilio_lookup = @lookups_client.phone_numbers.get(phone, type: 'carrier')
    carrier = twilio_lookup.carrier['name']
    return carrier
  end

  def email_admins(subject, body="")
    Pony.mail(:to => 'phil.esterman@yale.edu',
              :from => 'phil.esterman@yale.edu',
              :headers => { 'Content-Type' => 'text/html' },
              :subject => subject,
              :body => body)
  end

  def notify_admins(subject, body="")
    email_admins(subject, body)
    text_body   = subject + ":\n" + body
    phil = '+15612125831'
    puts "NOTIFYING ADMINS......."
    if text_body.length < 360
      MessageWorker.perform_async(text_body, phil, ENV['ST_USER_REPLIES_NO'])
    else
      MessageWorker.perform_async(subject, phil, ENV['ST_USER_REPLIES_NO'])
    end
  end

  # Does the carrier need 160-char segments? 
  def good_carrier?(carrier)
    if carrier != SPRINT &&
      carrier != ATT &&
      carrier != T_MOBILE
      return true
    else 
      return false
    end 
  end

  # Sleep only in production
  def sleep_in_prod(sec)
    if ENV['RACK_ENV'] == 'production'
      sleep sec
    else
      puts "fake sleep for #{sec}s"
    end
  end

  
end
