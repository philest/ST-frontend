require 'twilio-ruby'

#internationalization
require 'sinatra/r18n'

#set default locale to english
# R18n.default_places = '../i18n/'
R18n::I18n.default = 'en'


translations_path = File.expand_path(File.dirname(__FILE__) + '/../i18n')
R18n.default_places { translations_path }

#temp: constants not yet translated
require_relative '../constants'
#constants (untranslated)
include Text

#sending messages
require_relative '../message'
require_relative '../messageSeries'
require_relative '../workers/next_message_worker'
require_relative '../helpers.rb'

#the models
require_relative '../models/user' #add User model



##
# Reply to a user's series choice.
#   - Set that user's series. 
#   - Give that user the first in the series. 
#   - Reply when given invalid response. 
#  
def series_choice(user_id, params)

  @user = User.find(user_id)
  
  messageSeriesHash = MessageSeries.
                        getMessageSeriesHash

  if !@user.subscribed
    @user.update(subscribed: true)
    @user.update(next_index_in_series: 0)
  end


  # isolated letter
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

end
