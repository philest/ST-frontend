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

require_relative '../config/environments' #DB configuration
require_relative '../models/user' #add User model
require_relative '../models/experiment' #add User model

require_relative '../helpers/routes_helper'
require_relative '../helpers/sms_response_helper'

set :root, File.join(File.dirname(__FILE__), '../')

#scheduled background jobs 
require 'sidekiq'
require 'sidetiq'
require 'sidekiq/web'
require 'sidekiq/api' 

#twilio texting API
require 'twilio-ruby'

#email, to learn of failurs
require 'pony'
require_relative '../config/pony'

#internationalization
require 'sinatra/r18n'

#misc
require 'redis'
require_relative '../config/initializers/redis'

#sending mmessages 
require_relative '../message'
require_relative '../messageSeries'
require_relative '../workers/some_worker'
require_relative '../helpers.rb'

configure :production do
  require 'newrelic_rpm'
end


#temp: constants not yet translated
require_relative '../constants'
require_relative '../experiment/experiment_constants'

require_relative '../experiment/form_success'

#constants (untranslated)
include Text
include ExperimentConstants

#set default locale to english
# R18n.default_places = '../i18n/'
R18n::I18n.default = 'en'

#set mode (production or test)
MODE ||= ENV['RACK_ENV']
PRO ||= "production"
TEST ||= "test"

#########  ROUTES  #########

# Admin authentication, from Sinatra.
helpers RoutesHelper

enable :sessions

helpers SMSResponseHelper

#root
get '/' do
    erb :main
end

#experiment dashboard
get '/admin' do
    protected!
    #pull up experiments for dash
    @active_experiments = Experiment.where("active = true")
    @inactive_experiments = Experiment.where("active = false")
    erb :experiment_dashboard
end

#with form-selected options, create_experiment().
post '/form_success' do
	form_success()
end


#twilio failed: no valid response for sms.
get '/failed' do
    Helpers.smsRespondHelper("StoryTime: Hi! " + 
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


#begin sidetiq recurrence bkg tasks
get '/worker' do
    SomeWorker.perform_async 
    redirect to('/')
end

get '/mp3' do
    send_file File.join(settings.public_folder, 
                            'storytime_message.mp3')
end

