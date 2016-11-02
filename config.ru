require 'bundler'
require './app/app'
require 'sass/plugin/rack'

Sass::Plugin.options[:style] = :compressed
use Sass::Plugin::Rack

run Sinatra::Application

# run Rack::URLMap.new('/' => Sinatra::Application)
