$stdout.sync = true
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'bundler'
require 'rack'
require_relative 'config/environment'
get_db_connection()
require_relative 'app/app'
require 'sass/plugin/rack'
require_relative 'lib/app'
require_relative 'config/initializers/locale' # language files

require_relative 'config/initializers/airbrake'
require_relative 'config/initializers/aws'

Sass::Plugin.options[:style] = :compressed
use Sass::Plugin::Rack

use Airbrake::Rack::Middleware

run Rack::URLMap.new({
  '/' => App,
  '/enroll' => Enroll, 
  '/sidekiq' => Sidekiq::Web
})



# run Rack::URLMap.new('/' => Sinatra::Application)







