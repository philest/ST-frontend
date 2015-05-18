require 'stalker'
require 'twilio-ruby'


include Stalker

job 'reminders.send' do 
	puts "I JUST SENT THE TEST MESSAGE"
end
