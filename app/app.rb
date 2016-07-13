#  app.rb                                     Phil Esterman     
# 
#  The routes controller. Uses helpers to reply to SMS. 
#  --------------------------------------------------------

#########  DEPENDENCIES  #########

#config the load path 
require 'bundler/setup'

#siantra dependencies 
require 'sinatra'
require 'sinatra/activerecord' #sinatra w/ DB
require "sinatra/reloader" if development?

#for access in views
require_relative '../config/environments' #DB configuration
require_relative '../models/follower'

#helpers
require_relative '../helpers/routes_helper'

set :root, File.join(File.dirname(__FILE__), '../')

#scheduled background jobs 
require 'sidekiq'
require 'sidetiq'
require 'sidekiq/web'
require 'sidekiq/api' 


configure :production do
  require 'newrelic_rpm'
  set :static_cache_control, [:public, :max_age => 600]
end

# Error tracking. 
require 'airbrake'
require_relative '../config/initializers/airbrake'
use Airbrake::Rack::Middleware


#set mode (production or test)
MODE ||= ENV['RACK_ENV']
PRO ||= "production"
TEST ||= "test"

#########  ROUTES  #########

# Admin authentication, from Sinatra.
include RoutesHelper
helpers RoutesHelper

enable :sessions

#root
get '/' do
    erb :main
end


get '/privacy' do
  erb :privacy_policy
end

get '/signup' do
  erb :enroll
end

post '/success' do  
  create_invite(params) 
  erb :success
end

post '/demo_success' do 
  send_demo(params)
  redirect to('/')
end


get '/read' do
  redirect to('/signup')
end

get '/start' do
  redirect to('/signup')
end

get '/go' do
  redirect to('http://m.me/490917624435792')
end


# Documenation. 
get '/doc/' do 
  File.read(File.join('public', 'doc/_index.html'))
end

get '/doc' do
  redirect to('/doc/')
end

# Resources
get '/resources' do 
  protected!
  erb :resources
end

get '/resources/' do 
  redirect to('/resources')
end 

get '/team' do 
  erb :team
end

get '/join' do 
  erb :job_board
end

get '/product_lead' do 
  erb :"jobs/product"
end

get '/developer' do 
  erb :"jobs/developer"
end 

get '/pilots' do 
  erb :"jobs/pilots"
end 

get '/schools' do 
  erb :"jobs/schools"
end 

get '/illustrator' do 
  erb :"jobs/illustrator"
end 

get '/design' do 
  erb :"jobs/design"
end 


post '/get_updates_form_success' do 
  create_follower(params)
  redirect to('/join')
end

post '/enroll_families_form_success' do 

  enroll_families(params)
  erb :internal_success
end


get '/signup/flyer' do
  erb :flyer
end

# redirect to Messenger app. 
get '/books' do
  redirect to('http://m.me/490917624435792')
end







#twilio failed: no valid response for sms.
get '/failed' do
    TwilioHelper.smsRespondHelper("StoryTime: Hi! " + 
        "We're updating StoryTime now and are offline, " +
        "but check back in the next day!")
end

#voice call
get '/called' do
  Twilio::TwiML::Response.new do |r|
    r.Play "http://www.joinstorytime.com/mp3"
  end.text
end


 
get '/mp3' do
    send_file File.join(settings.public_folder, 
                            'storytime_message.mp3')
end

