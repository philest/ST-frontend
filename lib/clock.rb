require 'rubygems'
require 'clockwork'
require 'stalker'


module Clockwork
  handler do |job|
  	Stalker.enqueue(job)
    puts "Running #{job}"
  end



every(4.seconds, 'reminders.send') 


end

