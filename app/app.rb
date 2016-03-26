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
require_relative '../models/user' #add User model
require_relative '../models/experiment' #add Experiment model
require_relative '../models/follower'

#helpers
require_relative '../helpers/routes_helper'
require_relative '../helpers/sms_response_helper'

set :root, File.join(File.dirname(__FILE__), '../')

#scheduled background jobs 
require 'sidekiq'
require 'sidetiq'
require 'sidekiq/web'
require 'sidekiq/api' 

require_relative '../experiment/experiment_constants'
require_relative '../experiment/form_success'


configure :production do
  require 'newrelic_rpm'
end

# Error tracking. 
require 'airbrake'
require_relative '../config/initializers/airbrake'
use Airbrake::Rack::Middleware


include ExperimentConstants

#set mode (production or test)
MODE ||= ENV['RACK_ENV']
PRO ||= "production"
TEST ||= "test"

#########  ROUTES  #########

# Admin authentication, from Sinatra.
helpers RoutesHelper
helpers SMSResponseHelper

enable :sessions

#root
get '/' do
    erb :main
end


get '/learn-more' do
  send_file File.join(settings.public_folder, 'About_StoryTime.pdf')
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

#experiment dashboard
get '/admin' do
  protected!
  #pull up experiments for dash
  @active_experiments = Experiment.where("active = true")
  @inactive_experiments = Experiment.where("active = false")
  erb :experiment_dashboard
end

get '/team' do 
  erb :team
end

get '/join' do 
  erb :job_board
end

get '/curriculum' do 
  erb :"jobs/curriculum"
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


#with form-selected options, create_experiment().
post '/form_success' do
	form_success()
end

post '/get_updates_form_success' do 
  create_follower(params)
  redirect to('/join')
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

# register an incoming SMS
get '/sms' do   
    config_reply(params)
end

# Testing: mock a received SMS
get '/test/:From/:Body/:Carrier' do
    config_reply(params)
end
 
get '/mp3' do
    send_file File.join(settings.public_folder, 
                            'storytime_message.mp3')
end

