require 'sinatra/activerecord'
require_relative '../models/user'           #add the user model
require 'sidekiq'

require_relative '../message'
require_relative '../messageSeries'
require_relative '../helpers'

require_relative '../constants'


class NextMessageWorker
  include Sidekiq::Worker
  include Text
    
    sidekiq_options :queue => :critical
    sidekiq_options retry: false #if fails, don't resent (multiple texts)

    #Poll more often, so peeps rightly get their messages 
    Sidekiq.configure_server do |config|
      config.average_scheduled_poll_interval = 2
    end





  def perform(sms, mms_arr, user_phone)

  	@user = User.find_by(phone: user_phone)


    #handle strings
    if mms_arr.class == String
      mms_arr = [mms_arr]
    end


  	# #testing
  	# if ENV['RACK_ENV'] == 'test'
  	# 	@user ||= User.create(phone: user_phone)
  	# end

  	messageSeriesHash = MessageSeries.getMessageSeriesHash


    if mms_arr.empty? 

      puts "Something Broke: This shouldn't ever be empty."

    elsif mms_arr.length == 1#if last MMS, send with SMS
  		Helpers.fullSend(sms, mms_arr.shift, @user.phone, Helpers::NO_WAIT)
  		puts "finished the message stack: #{@user.phone}"

      #updating story or series number after last part.
      #next_index_in_series == nil (or series_choice == nil?) means that you're not in a series
      if @user.next_index_in_series != nil
        @user.update(next_index_in_series: (@user.next_index_in_series + 1))

        #exit series if time's up
        if @user.next_index_in_series == messageSeriesHash[@user.series_choice + @user.series_number.to_s].length

          ##return variable to nil: (nil, which means "you're asking the wrong question-- I'm not in a series")
          @user.update(next_index_in_series: nil)
          @user.update(series_choice: nil)
          #get ready for next series
          @user.update(series_number: @user.series_number + 1)
        end

      else

        if sms != Text::FIRST_SMS
        @user.update(story_number: @user.story_number + 1)
        end
        
      end

      #total message count
      @user.update(total_messages: @user.total_messages + 1)


  	else #not last MMS...
  		Helpers.new_just_mms_no_wait(mms_arr.shift, @user.phone)
  		NextMessageWorker.perform_in(Helpers::MMS_WAIT.seconds, sms, mms_arr, @user.phone)
    end



  end




end
