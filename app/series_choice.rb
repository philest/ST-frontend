require 'twilio-ruby'

#internationalization
require 'sinatra/r18n'

#set default locale to english
# R18n.default_places = '../i18n/'
R18n::I18n.default = 'en'


translations_path = File.expand_path(File.dirname(__FILE__) + '/../i18n')
R18n.default_places { translations_path }

#temp: constants not yet translated
require_relative '../i18n/constants'
#constants (untranslated)
include Text

#sending messages
require_relative '../stories/story'
require_relative '../stories/storySeries'
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

  # Get hash of story series.
  messageSeriesHash = MessageSeries.
                        getMessageSeriesHash
  # Resubscribe, if dropped.
  if !@user.subscribed
    @user.update(subscribed: true)
    @user.update(next_index_in_series: 0)
  end

  # Gave an isolated letter choice.
  if (body = /(\s|\A|'|")[a-zA-z](\s|\z|'|")/.match(params[:Body]))
    # Convert from Match group to first match.
    body = body.to_s
    # Grab the letter.
    body = /[a-zA-z]/.match(body)
    body = body.to_s
    body.downcase!

  # Gave the word.
  # (Its first letter matches a series choice.)
  elsif (body = /\A\s*[a-zA-Z]/.match(params[:Body])) && 
           MessageSeries.codeIsInHash(body.to_s +
             @user.series_number.to_s)

    body = body.to_s
    body.downcase!

  # No valid choice: default to first story. 
  else
    
    # Email us, so we avoid this. 
    if MODE == PRO &&
         @user.phone != "+15612125831"

      Pony.mail(:to => 'phil.esterman@yale.edu',
        :cc => 'henok.addis@yale.edu',
        :from => 'phil.esterman@yale.edu',
        :subject => 'StoryTime: an unknown series choice',
        :body => "A user texted in an unknown choice
            on series #{@user.series_number.to_s}. 

            From: #{params[:From]}
            Body: #{params[:Body]} .")
    end
    # Two choices for each series,
    # so take twice the current series number
    # to get default.
    body = messageSeriesHash.keys[@user.series_number * 2] #t0
    body = body[0] #t
  end

  # Push back to zero in case 
  # changed to 999 to denote one 'day' after
  @user.update(next_index_in_series: 0)

  # A valid choice.
  if MessageSeries.codeIsInHash(body + @user.series_number.to_s)
      
    # Update the series choice.
    @user.update(series_choice: body)
    @user.update(awaiting_choice: false)

    # Grab stories from the series hash. 
    story = messageSeriesHash[@user.series_choice +
                               @user.series_number.to_s][0]
    if @user.mms == true
      # In case of just one photo, this also updates user-info.
      # Sends last photo in advance
      NextMessageWorker.perform_in(17.seconds, story.getSMS,
                story.getMmsArr[1..-1], @user.phone)
      
       # Don't need to send stack 
       # if a one-pager.
      if story.getMmsArr.length > 1
        # Reply with first photo immediately
        Helpers.mms(story.getMmsArr[0], @user.phone)
      else
        # If just one photo, reply
        # with MMS and SMS joint. 
        Helpers.text_and_mms(story.getSMS,
          story.getMmsArr[0], @user.phone)
      end

    else # Just SMS.
      NextMessageWorker.updateUser(@user.phone,
                                   story.getPoemSMS)
      Helpers.text(story.getPoemSMS,
                   story.getPoemSMS,
                   @user.phone)    
    end
  # An invalid choice. 
  else        
    Helpers.text(R18n.t.error.bad_choice, 
                 R18n.t.error.bad_choice,
                 @user.phone)
  end

end
