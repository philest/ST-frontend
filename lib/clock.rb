require 'rubygems'
require 'clockwork'
require File.expand_path('../config/environment', __FILE__)


module Clockwork
  handler do |job|
    puts "Running #{job}"
  end



every(2.minutes, 'Queueing the job to check ready reminders') { Delayed::Job.enqueue IntervalJob.new }








end

