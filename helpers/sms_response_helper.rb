#  helpers/sms_repsonse_helper.rb            Phil Esterman   
# 
#  Main helper to reply to an SMS. Core logic's here! 
#  --------------------------------------------------------

#enrollment
require_relative '../app/enroll'

#misc: remember who quits
require 'redis'
require_relative '../config/initializers/redis'

#email, to learn of failures
require 'pony'
require_relative '../config/pony'

#twilio texting API
require 'twilio-ruby'

#internationalization
require 'sinatra/r18n'
#set default locale to english
# R18n.default_places = '../i18n/'
R18n::I18n.default = 'en'

#sending messages 
require_relative './twilio_helper.rb'

#temp: constants not yet translated
require_relative '../i18n/constants'
include Text

require_relative '../app/series_choice'

module SMSResponseHelper

  ##
  # Configure the session to record the last 
  # response and time, reset the new. 
  #
  # [params] user data
  #   - {Carrier: "ATT", Body: "STORY"} etc.
  #
  def config_session(params)
  ## Remeber last response and time ##
  #new becomes old
    session["prev_body"] = session["new_body"] 
    session["prev_time"] = session["new_time"]
    session["now_for_us"] = session["next_for_us"]
    #reset the new
    session["new_body"] = params[:Body].strip
    session["new_time"] = Time.now.utc
    session["next_for_us"] = false #default: don't send us their response.
  end

  ##
  # Was the user in the midst of a series when
  # dropped?
  #
  def in_series?(user_phone)
    user = User.find_by_phone user_phone
    
    user.next_index_in_series == 999 || 
      user.awaiting_choice == true
  end

  ##
  # Return whether to skip a repeat. Repeat when:
  #   - 1) the same response had been sent 
  #   - 2) in the previous 55 seconds 
  #
  def repeat?(body)
    if session["prev_body"] &&
         session["prev_body"] == body &&
         session["prev_time"] - 55 < Time.now.utc

      repeat = true
    else 
      repeat = false 
    end
  ##
  # Return String of story weekdays for reply,
  # with abbreviations for Sprint.
  end


  #
  # Schedule depends on days/week:  
  # 1: Mon
  # 2: Tues, Thurs
  # 3: Mon, Wed, Fri
  def get_day_names(days_per_week, carrier)
    day_names = ''
   
    case days_per_week
    when 1
        day_names = R18n.t.weekday.wed
    when 2, nil
      if carrier == SPRINT
        day_names =  R18n.t.weekday.sprint.tue +
         "/" + R18n.t.weekday.sprint.th
      else       
        day_names = R18n.t.weekday.normal.tue +
         "/" + R18n.t.weekday.normal.th
      end
    when 3
      if carrier == SPRINT
        day_names = R18n.t.weekday.letters.M + 
           "-" + R18n.t.weekday.letters.W + 
           "-" + R18n.t.weekday.letters.F
      else       
        day_names = R18n.t.weekday.mon + 
           "/" + R18n.t.weekday.wed +
           "/" + R18n.t.weekday.fri
      end
    else
      puts "ERR: invalid days of week"
    end

    day_names
  end


  ##
  # Set locale, then reply.
  #   - defaults to English 
  #  
  # [parmams] fake user data
  #  - {Carrier: "ATT", Body: "STORY"} etc.
  #  - Mocked in testing; normally given by Twilio
  def config_reply(params)  
    #1. Set locale. 
    @user = User.find_by_phone params[:From]
    
    if @user
      locale = @user.locale
    elsif params[:locale]
      locale = params[:locale]
    else
      locale = "en"
    end

    #2. Reply. 
    reply(params, locale)
  end

  ##
  # Return a cleaned string.
  #   - Strips trailing, leading whitespace.
  #   - Downcases.
  #   - Removes punctuation. 
  #
  def clean_str(str)
    str = str.strip
    str.downcase!
    str.gsub!(/[\.\,\!\?\']/, '')
    str
  end

  ##
  # Reply to an incoming text 
  # (or enroll the user, if appropriate)
  # 
  # [params] user data
  #   - {Carrier: "ATT", Body: "STORY"} etc.
  # [locale] the user's locale
  #   - "en"
  def reply(params, locale)

    # Standardize the incoming SMS.
    params[:Body] = clean_str(params[:Body])

    config_session params
    # Get the user.
    @user = User.find_by_phone(params[:From])

    # Set this thread's locale.  
    if locale != nil && 
         @user != nil

      i18n = R18n::I18n.new(@user.locale, ::R18n.default_places)
      R18n.thread_set(i18n)
    end

    case params[:Body]

    # STORY
    when R18n.t.commands.story
      # Enroll new user. 
      if @user == nil ||
           @user.sample == true

        app_enroll(params, params[:From], locale, STORY)
      # Autodropped from series, now re-subscribing.
      elsif @user.subscribed == false && 
              in_series?(@user.phone)

        # Resubscribe. 
        @user.update(subscribed: true)
        msg = R18n.t.stop.resubscribe.short +
              R18n.t.choice.no_greet[@user.series_number]
              #longer message, give more newlines
        @user.update(next_index_in_series: 0)
        @user.update(awaiting_choice: true)

        TwilioHelper.text(msg, msg, @user.phone)

      # Dropped manually, out of series
      elsif @user.subscribed == false 
        # Resubscribe. 
        @user.update(subscribed: true)
        TwilioHelper.text(R18n.t.stop.resubscribe.long, 
                     R18n.t.stop.resubscribe.long,
                     @user.phone)
      end

    # SAMPLE or EXAMPLE
    when R18n.t.commands.sample,
         R18n.t.commands.example

      app_enroll(params, params[:From], locale, SAMPLE)

    # HELP
    when R18n.t.commands.help
      # Get string of weekdays for reply.
      day_names = get_day_names(@user.days_per_week,
                               @user.carrier)
      TwilioHelper.text(R18n.t.help.normal(day_names).to_str,
                   R18n.t.help.sprint(day_names).to_str,
                   @user.phone)

    # BREAK
    when R18n.t.commands.break
      @user.update(on_break: true)
      @user.update(days_left_on_break: Text::BREAK_LENGTH)

      TwilioHelper.text(R18n.t.break.start,
                   R18n.t.break.start,
                   @user.phone)

    # STOP
    when R18n.t.commands.stop,
         "stop now"

      if MODE == PRO
      # TODO Add to list in Redis. 
      # Report quitters to us by email.
        Pony.mail(:to => 'phil.esterman@yale.edu',
              :cc => 'henok.addis@yale.edu',
              :from => 'phil.esterman@yale.edu',
              :subject => 'StoryTime: A user quit.',
              :body => "A user texted STOP. 

                  From: #{params[:From]}
                  Body: #{params[:Body]}
                  Message #: #{@user.total_messages}
                  
                  Body of prev text: #{session["prev_body"]}
                  Time of prev text: #{session["prev_time"]}")
      end

      #change subscription, then text us. 
      @user.update(subscribed: false)
      note = params[:From].to_s + "quit StoryTime."
      TwilioHelper.new_text(note, note, "+15612125831")

    # TEXT
    when R18n.t.commands.text.to_s
      #change mms to sms
      @user.update(mms: false)
      TwilioHelper.text(R18n.t.mms_update,
                   R18n.t.mms_update,
                   @user.phone)

    # THANKS or THANK YOU 
    when R18n.t.misc.sms.thanks.to_s,
         R18n.t.misc.sms.thank_you.to_s

      TwilioHelper.text(R18n.t.misc.reply.sure,
                   R18n.t.misc.reply.sure,
                   @user.phone)

    # WHO IS THIS or WHO'S THIS
    when R18n.t.misc.sms.whos_this.to_s,
         R18n.t.misc.sms.who_is_this.to_s

      TwilioHelper.text(R18n.t.misc.reply.
                      who_we_are(@user.days_per_week).to_s,
                   R18n.t.misc.reply.
                      who_we_are(@user.days_per_week).to_s,
                   @user.phone)

    else  

      ### NOT STANDARD RESPONSE ### 

      # Someone replied to the SAMPLE text.
      if @user &&
           @user.sample &&
           params[:Body] != R18n.t.commands.story
        
        TwilioHelper.text(R18n.t.sample.post,
                     R18n.t.sample.post,
                     @user.phone)

      # Unregistered user.
      elsif @user == nil
        # Email us about problem.
        if MODE == PRO &&
            params[:From] != "+15612125831"

          Pony.mail(:to => 'phil.esterman@yale.edu',
                    :cc => 'henok.addis@yale.edu',
                    :from => 'phil.esterman@yale.edu',
                    :subject => 'StoryTime: an unknown '\
                                'SMS (non-user)',
                    :body => 'An unregistered user texted '\
                             'in an unknown response.'\
                             "\n\nFrom: #{params[:From]}\n"\
                             "Body: #{params[:Body]} .")
        end

        TwilioHelper.text(R18n.t.error.no_signup_match, 
                     R18n.t.error.no_signup_match,
                     params[:From])

      # Send the message to us. 
      elsif session["now_for_us"]
        TwilioHelper.new_text("#{@user.phone} sent: #{params[:Body]}",
                         "#{@user.phone} sent: #{params[:Body]}",
                         "+15612125831")
        TwilioHelper.text(R18n.t.to_us.thanks.to_s, 
                     R18n.t.to_us.thanks.to_s,
                     @user.phone)
       
      # A Series Choice.  
      elsif @user.awaiting_choice ||
              (!@user.subscribed &&
               /(\s|\A|'|")[a-zA-z](\s|\z|'|")/.
               match(params[:Body]))
             # 2nd condition: A dropped user's choice. 

        series_choice_reply(@user.id, params)

      ## Response Not Recognized  
      else 

        ## Report this to us by email (and SMS)
        if MODE == PRO &&
             params[:From] != "+15612125831"

          Pony.mail(:to => 'phil.esterman@yale.edu',
                :cc => 'henok.addis@yale.edu',
                :from => 'phil.esterman@yale.edu',
                :subject => 'StoryTime: an unknown SMS (user)',
                :body => (note = "A registered user texted in"\
                                 " an unknown response."\
                                 "\n\nFrom: #{params[:From]}"\
                                 "\nBody: #{params[:Body]} ."))
          # Send us text, too.
          TwilioHelper.new_text(note, note, "+15612125831")
        end

           # Skip a repeated text.
        if repeat?(params[:Body]) 
          puts "DONT send this repeat: message"\
               " #{session["prev_body"]}"\
               " was sent already"
        else
          # Forward their next text to us. 
          session["next_for_us"] = true 

          TwilioHelper.text(R18n.t.error.no_option.to_s, 
                       R18n.t.error.no_option_sprint.to_s,
                       @user.phone)
        end 

      end # list of abnormal responses 
         
    end # case-statement

  end # reply()

end # module

