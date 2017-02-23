$stdout.sync = true
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'bundler'
require 'rack'
require 'rack/contrib'
require_relative 'config/environment'
get_db_connection()
require_relative 'app/app'
require_relative 'app/register'
require 'sass/plugin/rack'
require_relative 'lib/app'
require_relative 'config/initializers/locale' # language files

require_relative 'config/initializers/airbrake'
require_relative 'config/initializers/aws'



puts ENV['RACK_ENV']
if ENV['RACK_ENV'] == 'production'
  puts "it is!"
  require 'rack/ssl'
  use Rack::SSL
end

Sass::Plugin.options[:style] = :compressed
use Sass::Plugin::Rack


use ::Rack::PostBodyContentTypeParser
use Airbrake::Rack::Middleware

run Rack::URLMap.new({
  '/' => App,
  '/enroll' => Enroll,
  '/register' => Register,
  '/sidekiq' => Sidekiq::Web
})

# run Rack::URLMap.new('/' => Sinatra::Application)







