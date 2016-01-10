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

#sending mmessages 
require_relative '../message'
require_relative '../messageSeries'
require_relative '../workers/some_worker'
require_relative '../helpers.rb'

#temp: constants not yet translated
require_relative '../constants'
include Text

module SMSResponseHelper

  ##
  # Configure the sessions to record the last 
  # response and time, reset the new. 
  #
  # [params] user data
  #   - {Carrier: "ATT", Body: "STORY"} etc.
  #
  def config_sessions(params)
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

  # Set locale, then reply.
  #   - defaults to English 
  #  
  # [parmams] fake user data
  #    - {Carrier: "ATT", Body: "STORY"} etc.
  #    - Mocked in testing; normally given by Twilio
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


  # Reply to an incoming text 
  # (or enroll the user, if appropriate)
  # 
  # [params] user data
  #   - {Carrier: "ATT", Body: "STORY"} etc.
  # [locale] the user's locale
  #   - "en"
  def reply(params, locale)

    # STANDARDIZE SMS # 
    #strip whitespace (trailing and leading)
    params[:Body] = params[:Body].strip
    params[:Body].downcase!
    #rid of punctuation
    params[:Body].gsub!(/[\.\,\!]/, '')
    
    config_sessions params
    @user = User.find_by_phone(params[:From]) #check if already registered.

    #set this thread's locale.  
    if locale != nil && @user != nil
        i18n = R18n::I18n.new(@user.locale, ::R18n.default_places)
        R18n.thread_set(i18n)
    end

    ### REPLY WORKFLOW ###
    #STORY
    if params[:Body] == R18n.t.commands.story && 
            (@user == nil || @user.sample == true)

        app_enroll(params, params[:From], locale, STORY)

    #SAMPLE or EXAMPLE
    elsif params[:Body] == R18n.t.commands.sample ||
            params[:Body] == R18n.t.commands.example

        app_enroll(params, params[:From], locale, SAMPLE)

    #new user...but not SAMPLE or STORY. 
    elsif @user == nil
        #send us email about problem
        if MODE == PRO and params[:From] != "+15612125831"
            Pony.mail(:to => 'phil.esterman@yale.edu',
                      :cc => 'henok.addis@yale.edu',
                      :from => 'phil.esterman@yale.edu',
                      :subject => 'StoryTime: an unknown SMS (non-user)',
                      :body => "An unregistered user texted in an unknown response. 

                                From: #{params[:From]}
                                Body: #{params[:Body]} .")
        end

        Helpers.text(R18n.t.error.no_signup_match, 
            R18n.t.error.no_signup_match, params[:From])
    #post-SAMPLE (if replied to SAMPLE)    
    elsif @user.sample == true
        Helpers.text(R18n.t.sample.post, R18n.t.sample.post,
                                                @user.phone)
    #if auto-dropped (or if choose to drop mid-series), returning
    elsif (@user.next_index_in_series == 999 || 
                 @user.awaiting_choice == true) &&
          (@user.subscribed == false && 
                 params[:Body] == R18n.t.commands.story)

        #REACTIVATE SUBSCRIPTION
            @user.update(subscribed: true)
            msg = R18n.t.stop.resubscribe.short + 
                "\n\n" + R18n.t.choice.no_greet[@user.series_number]
                     #longer message, give more newlines

            @user.update(next_index_in_series: 0)
            @user.update(awaiting_choice: true)

            Helpers.text(msg, msg, @user.phone)
    #if returning after manually stopping (not in mid - series)
    elsif @user.subscribed == false && 
            params[:Body] == R18n.t.commands.story 
        #REACTIVATE SUBSCRIPTION
        @user.update(subscribed: true)
        Helpers.text(R18n.t.stop.resubscribe.long, 
            R18n.t.stop.resubscribe.long, @user.phone)

    elsif params[:Body] == R18n.t.commands.help #Text::HELP option
        #default 2 days a week
        if @user.days_per_week == nil
            @user.update(days_per_week: 2)
        end

        #find the day names
        case @user.days_per_week
        when 1
                dayNames = R18n.t.weekday.wed

        when 2, nil
            if @user.carrier == SPRINT
                dayNames =  R18n.t.weekday.sprint.tue +
                 "/" + R18n.t.weekday.sprint.th
            else           
                dayNames = R18n.t.weekday.normal.tue +
                 "/" + R18n.t.weekday.normal.th
            end
        when 3
            if @user.carrier == SPRINT
                dayNames = R18n.t.weekday.letters.M + 
                     "-" + R18n.t.weekday.letters.W + 
                     "-" + R18n.t.weekday.letters.F
            else           
                dayNames = R18n.t.weekday.mon + 
                     "/" + R18n.t.weekday.wed +
                     "/" + R18n.t.weekday.fri
            end
        else
            puts "ERR: invalid days of week"
        end

        Helpers.text(R18n.t.help.normal(dayNames).to_s,
             R18n.t.help.sprint(dayNames).to_s, @user.phone)
    elsif session["now_for_us"]
            #send it to us.
            Helpers.new_text("#{@user.phone} sent: #{params[:Body]}")
            
            Helpers.text(R18n.t.to_us.thanks.to_s, 
                         R18n.t.to_us.thanks.to_s,
                                      @user.phone)

    elsif params[:Body] == R18n.t.commands.break
        @user.update(on_break: true)
        @user.update(days_left_on_break: Text::BREAK_LENGTH)

        Helpers.text(R18n.t.break.start, R18n.t.break.start,
                                                @user.phone)

    elsif params[:Body] == "stop now" ||
          params[:Body] == R18n.t.commands.stop #STOP option

        if MODE == PRO
        #SAVE QUITTERS
            REDIS.set(@user.phone+":quit", "true") 
        #Report quitters to us by email
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

        #change subscription
        @user.update(subscribed: false)
        note = params[:From].to_s + "quit StoryTime."
        Helpers.new_text(note, note, "+15612125831")


    elsif params[:Body] == R18n.t.commands.text.to_s #TEXT option        
        #change mms to sms
        @user.update(mms: false)
        Helpers.text(R18n.t.mms_update, R18n.t.mms_update,
                                              @user.phone)
    #Responds with a letter when prompted to choose a series
    #Account for quotations
    elsif @user.awaiting_choice == true or
          (@user.subscribed == false and   #dropped user choosing
          /(\s|\A|'|")[a-zA-z](\s|\z|'|")/.match(params[:Body])) 

        messageSeriesHash = MessageSeries.
                      getMessageSeriesHash

        if not @user.subscribed
            @user.update(subscribed: true)
            @user.update(next_index_in_series: 0)
        end


            #isolated letter
        if (body = /(\s|\A|'|")[a-zA-z](\s|\z|'|")/.match(params[:Body]))
            body = body.to_s #convert from Match group to first match.
            #isolate the letter from space and quotes
            body = /[a-zA-z]/.match(body)
            body = body.to_s
            body.downcase!

            #first letter of word-- IF first letter is valid!!!
        elsif (body = /\A\s*[a-zA-Z]/.match(params[:Body])) and 
                         MessageSeries.codeIsInHash(body.to_s +
                                      @user.series_number.to_s)
            body = body.to_s
            body.downcase!
        else #default to first one.
            
            if MODE == PRO && @user.phone != "+15612125831" 
                Pony.mail(:to => 'phil.esterman@yale.edu',
                  :cc => 'henok.addis@yale.edu',
                  :from => 'phil.esterman@yale.edu',
                  :subject => 'StoryTime: an unknown series choice',
                  :body => "A user texted in an unknown choice
                            on series #{@user.series_number.to_s}. 

                            From: #{params[:From]}
                            Body: #{params[:Body]} .")
            end

            body = messageSeriesHash.keys[@user.series_number * 2] #t0
            body = body[0] #t
        end

        #push back to zero incase 
        #changed to 999 to denote one 'day' after
        @user.update(next_index_in_series: 0)

        #check if valid choice
        if MessageSeries.codeIsInHash(body + @user.series_number.to_s)
                
            #update the series choice
            @user.update(series_choice: body)
            @user.update(awaiting_choice: false)

            messageSeriesHash = MessageSeries.
                                    getMessageSeriesHash
            story = messageSeriesHash[@user.series_choice +
                                      @user.series_number.to_s][0]
            if @user.mms == true
                #incase of just one photo, this also updates user-info.
                #sends last photo in advance
                NextMessageWorker.perform_in(17.seconds, story.getSMS,
                                  story.getMmsArr[1..-1], @user.phone)
                 #don't need to send stack 
                 #if a one-pager.
                if story.getMmsArr.length > 1
                     #replies with first photo immediately
                    Helpers.mms(story.getMmsArr[0], @user.phone)
                else
                    #if just one photo, replies
                    #w/ photo and sms
                    Helpers.text_and_mms(story.getSMS,
                      story.getMmsArr[0], @user.phone)
                end

            else # just SMS
                NextMessageWorker.updateUser(@user.phone,
                                        story.getPoemSMS)
                Helpers.text(story.getPoemSMS, story.getPoemSMS,
                                                    @user.phone)      
            end
        else                
            Helpers.text(R18n.t.error.bad_choice, 
                R18n.t.error.bad_choice, @user.phone)
        end             


        #thanks or thank you
    elsif params[:Body] == R18n.t.misc.sms.thanks.to_s ||
          params[:Body] == R18n.t.misc.sms.thank_you.to_s
            
        Helpers.text(R18n.t.misc.reply.sure,
                     R18n.t.misc.reply.sure, @user.phone)
    elsif params[:Body] == R18n.t.misc.sms.whos_this.to_s ||
      params[:Body] == R18n.t.misc.sms.who_is_this.to_s
        
        Helpers.text(R18n.t.misc.reply.
                         who_we_are(@user.days_per_week).to_s,
            R18n.t.misc.reply.who_we_are(@user.days_per_week).
                                            to_s, @user.phone)
    #response matches nothing
    else
        repeat = false

        if session["prev_body"]
            if session["prev_body"] == params[:Body] and
                      session["prev_time"] - 100 < Time.now.utc and
                                              @user.awaiting_choice 
                repeat = true
            end
        end

        ##report this to us by email (and text)
        if MODE == PRO and params[:From] != "+15612125831"
            note = "A registered user texted in an unknown response. 

                                From: #{params[:From]}
                                Body: #{params[:Body]} ."

            Pony.mail(:to => 'phil.esterman@yale.edu',
                      :cc => 'henok.addis@yale.edu',
                      :from => 'phil.esterman@yale.edu',
                      :subject => 'StoryTime: an unknown SMS (user)',
                      :body => note)
            #send me text too
            Helpers.new_text(note, note, "+15612125831")
        end


        if not repeat
            Helpers.text(R18n.t.error.no_option.to_s, 
                  R18n.t.error.no_option_sprint.to_s,
                                         @user.phone)
        else
            puts "DONT send repeat: message #{session["prev_body"]} was sent already"
        end
        
    end#signup flow

  end

end