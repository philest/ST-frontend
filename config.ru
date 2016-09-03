require 'bundler'
require './app/app'
require 'sidekiq/web'
require 'sass/plugin/rack'

Sass::Plugin.options[:style] = :compressed
use Sass::Plugin::Rack


run Rack::URLMap.new('/' => Sinatra::Application, '/sidekiq' => Sidekiq::Web)
