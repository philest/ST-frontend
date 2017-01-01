require 'rack'
require 'airbrake'
# require 'airbrake/sidekiq'
require 'sidekiq'
require 'airbrake/sidekiq/error_handler'
require 'newrelic_rpm'

Airbrake.configure do |config|
  config.project_id = ENV['AIRBRAKE_PROJECT_ID']
  config.project_key = ENV['AIRBRAKE_API_KEY']
  config.environment = ENV['RACK_ENV'] || "development"
  config.logger.level = Logger::DEBUG
end