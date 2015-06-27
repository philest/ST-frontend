require 'sinatra/activerecord'
require_relative '../models/user'           #add the user model
require 'sidekiq'

require_relative '../message'
require_relative '../messageSeries'
require_relative '../helpers'

LAST = "last"
NORMAL = "normal"

class NextMessageWorker
  include Sidekiq::Worker
    
    sidekiq_options :queue => :critical
    sidekiq_options retry: false #if fails, don't resent (multiple texts)

  def perform(sms, mms_arr, user_phone)

  	@user = User.find_by(phone: user_phone)

  	# #testing
  	# if ENV['RACK_ENV'] == 'test'
  	# 	@user ||= User.create(phone: user_phone)
  	# end

  	messageSeriesHash = MessageSeries.getMessageSeriesHash


  	if mms_arr.length == 1#if last MMS, send with SMS
  		Helpers.fullSend(sms, mms_arr.shift, @user.phone, LAST)
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
        @user.update(story_number: @user.story_number + 1)
      end

      #total message count
      @user.update(total_messages: @user.total_messages + 1)


  	else #not last MMS...
  		Helpers.new_just_mms(mms_arr.shift, @user.phone)
  		NextMessageWorker.perform_in(20.seconds, sms, mms_arr, @user.phone)
  	end



  end




end
