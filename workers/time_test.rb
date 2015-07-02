require_relative './some_worker'

class TimeTest
    include Sidekiq::Worker

    def perform(args)
      raise (Time.now - Time.parse(args['start_time'])).to_i.to_s
      puts "It's : " + (Time.now - Time.parse(args['start_time'])).to_i.to_s
    end



end
