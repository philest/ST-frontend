require 'sidekiq'
require 'active_support/time'
require 'rack'

require 'twilio-ruby'

require 'airbrake'
require 'airbrake/sidekiq'
require_relative '../config/environment'
get_db_connection()


require_relative '../config/initializers/airbrake'

require_relative 'workers'