#  worker/next_message_worker.rb               Phil Esterman   
# 
#  Send an MMS, or MMS/SMS story asynchonously. 
#  Update the user if it's story.
#  --------------------------------------------------------

require 'sinatra/activerecord'
require_relative '../models/user'           #add the user model
require 'sidekiq'

require_relative '../stories/story'
require_relative '../stories/storySeries'
require_relative '../helpers/twilio_helper'

require_relative '../i18n/constants'
require 'sinatra/r18n'


class NextMessageWorker
  include Sidekiq::Worker
  include Text
    
    sidekiq_options :queue => :critical
    sidekiq_options retry: false #if fails, don't resent (multiple texts)

    #Poll more often, so peeps rightly get their messages 
    Sidekiq.configure_server do |config|
      config.average_scheduled_poll_interval = 1
    end



  def perform(sms, mms_arr, user_phone)
    
  	@user = User.find_by(phone: user_phone)


    #handle strings
    if mms_arr.class == String
      mms_arr = [mms_arr]
    end


    if mms_arr.empty? 
      puts "finished one-pic stack!"
      NextMessageWorker.updateUser(@user.phone, sms)

    elsif mms_arr.length == 1#if last MMS, send with SMS
  		TwilioHelper.fullSend(sms, mms_arr.shift, @user.phone, TwilioHelper::NO_WAIT)
  		puts "finished the message stack: #{@user.phone}"
      NextMessageWorker.updateUser(@user.phone, sms)

  	else #not last MMS...
  		TwilioHelper.mmsSend(mms_arr.shift, @user.phone)
  		NextMessageWorker.perform_in(TwilioHelper::MMS_WAIT.seconds, sms, mms_arr, @user.phone)
    end


  end

  #updates what story, series, choice, total_message, or index User is on.
  def self.updateUser(user_phone, sms)

      @user = User.find_by(phone: user_phone)

      storySeriesHash = StorySeries.getStorySeriesHash

      #updating story or series number after last part.
      #next_index_in_series == nil (or series_choice == nil?) means that you're not in a series
      if @user.next_index_in_series != nil
        @user.update(next_index_in_series: (@user.next_index_in_series + 1))

        
        #exit series if time's up
        if @user.next_index_in_series == storySeriesHash[@user.series_choice + @user.series_number.to_s].length

          ##return variable to nil: (nil, which means "you're asking the wrong question-- I'm not in a series")
          @user.update(next_index_in_series: nil)
          @user.update(series_choice: nil)
          #get ready for next series
          @user.update(series_number: @user.series_number + 1)

          @user.update(story_number: @user.story_number + 1) #update to get next story after finishing series
        end

      else

        #note first enrollment message
        if @user.total_messages > 0
           @user.update(story_number: @user.story_number + 1)
        end
        
      end

      #total message count
      @user.update(total_messages: @user.total_messages + 1)
  end




end
