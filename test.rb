require 'sinatra/activerecord'
require_relative './models/user' #add the user model
require 'twilio-ruby'

class Test

	@user = 'works'

	  def self.sendBadTimeSMS
		#if sprint
		puts @user

	  end

	Test.sendBadTimeSMS
end

