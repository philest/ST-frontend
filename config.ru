require 'bundler'
require './app/app'
require 'sidekiq/web'

run Rack::URLMap.new('/' => Sinatra::Application, '/sidekiq' => Sidekiq::Web)
