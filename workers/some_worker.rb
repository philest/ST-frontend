# require '.config/environments'


class SomeWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable
	
	sidekiq_options retry: false #if fails, don't resent (multiple texts)


  recurrence { hourly.minute_of_hour(0, 2, 4, 6, 8, 10,
  									12, 14, 16, 18, 20, 22, 24, 26, 28, 30,
  									32, 34, 36, 38, 40, 42, 44, 46, 48, 50,
  									52, 54, 56, 58) } #set explicitly because of ice-cube sluggishness

  def perform(*args)
    puts "doing hard work!!"
  end



end

