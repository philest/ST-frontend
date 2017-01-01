require 'sidekiq'
require 'active_support/time'
require 'rack'
require 'airbrake'
require 'airbrake/sidekiq/error_handler'
# redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/12'
redis_url = ENV['REDIS_URL'] || 'redis://localhost:6380/12'
# hopefull this will work out
# I'm giving 6 to puma and 1 to clock
Sidekiq.configure_client do |config|
    config.redis = { url: redis_url, size: 6 }
end

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url, size: 8 }
  config.error_handlers << Proc.new { |ex,ctx_hash| Airbrake.notify(ex, ctx_hash) }
end

# load all workers
Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/workers/*")
			.each {|f| require_relative f }

# st-enroll
# redis://h:p1r2v22ef77pn0eo13qb9t2ke3l@ec2-23-23-126-210.compute-1.amazonaws.com:22809
# 
# birdv
# redis://h:pbnhhkpgo4ss1n45sv1n0he4gqh@ec2-107-22-162-129.compute-1.amazonaws.com:12019

