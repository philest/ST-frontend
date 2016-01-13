#  app/series_choice.rb                  Phil Esterman   
# 
#  Invite, remind, drop, & reply to users about series
#  choices.  
#  --------------------------------------------------------

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

require_relative '../helpers/twilio_helper.rb'

#the models
require_relative '../models/user' #add User model


require_relative '../workers/new_text_worker'
require_relative '../workers/main_worker'


##
# Invite the user to choose a series.
#  - Update appropriate user attributes to
#    indicate waiting on choice. 
#
def series_choice_choose(user_id, note)

  # Get set for first in series
  user = User.find user_id
  user.update(next_index_in_series: 0)
  user.update(awaiting_choice: true)

  # Send invitation to choose.
  myWait = MainWorker.getWait(NewTextWorker::NOT_STORY)
  NewTextWorker.perform_in(myWait.seconds,
                           note + R18n.t.choice.greet[user.series_number],
                           NewTextWorker::NOT_STORY,
                           user.phone)
end




##
# Remind the user to choose a series.
#  - Update appropriate user attributes to
#    indicate this. 
#
def series_choice_remind(user_id, note)

  user = User.find user_id
  msg = R18n.t.no_reply.day_late + R18n.t.choice.no_greet[user.series_number]

  myWait = MainWorker.getWait(NewTextWorker::NOT_STORY)
  NewTextWorker.perform_in(myWait.seconds,
                           note + msg, NewTextWorker::NOT_STORY,
                           user.phone)

  user.update(next_index_in_series: 999)  
end


##
# Drop the user and notify her.
#  - Update appropriate user attributes to
#    indicate drop. 
#
def series_choice_drop(user_id, note)

  # Get set for first in series
  user = User.find user_id
  user.update(subscribed: false)
  user.update(awaiting_choice: false)

  myWait = MainWorker.getWait(NewTextWorker::NOT_STORY)
  NewTextWorker.perform_in(myWait.seconds,
                           R18n.t.no_reply.dropped.to_str,
                           NewTextWorker::NOT_STORY,
                           user.phone)
end




##
# Reply to a user's series choice.
#   - Set that user's series. 
#   - Give that user the first in the series. 
#   - Reply when given invalid response. 
#  
def series_choice_reply(user_id, params)

  @user = User.find(user_id)

  # Get hash of story series.
  storySeriesHash = StorySeries.
                        getStorySeriesHash
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
           StorySeries.codeIsInHash(body.to_s +
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
    body = storySeriesHash.keys[@user.series_number * 2] #t0
    body = body[0] #t
  end

  # Push back to zero in case 
  # changed to 999 to denote one 'day' after
  @user.update(next_index_in_series: 0)

  # A valid choice.
  if StorySeries.codeIsInHash(body + @user.series_number.to_s)
      
    # Update the series choice.
    @user.update(series_choice: body)
    @user.update(awaiting_choice: false)

    # Grab stories from the series hash. 
    story = storySeriesHash[@user.series_choice +
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
        TwilioHelper.mms(story.getMmsArr[0], @user.phone)
      else
        # If just one photo, reply
        # with MMS and SMS joint. 
        TwilioHelper.text_and_mms(story.getSMS,
          story.getMmsArr[0], @user.phone)
      end

    else # Just SMS.
      NextMessageWorker.updateUser(@user.phone,
                                   story.getPoemSMS)
      TwilioHelper.text(story.getPoemSMS,
                   story.getPoemSMS,
                   @user.phone)    
    end
  # An invalid choice. 
  else        
    TwilioHelper.text(R18n.t.error.bad_choice, 
                 R18n.t.error.bad_choice,
                 @user.phone)
  end

end
