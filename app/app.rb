#  app.rb          Phil Esterman, David McPeek, Aubrey Wahl     
# 
#  The routes controller. Uses helpers to reply to SMS. 
#  --------------------------------------------------------

#########  DEPENDENCIES  #########

#config the load path 
require 'bundler/setup'

#siantra dependencies 
require 'sinatra/base'
require "bundler/setup"

require 'twilio-ruby'

#for access in views
require_relative '../config/initializers/aws'

#helpers
require_relative '../helpers/routes_helper'
require_relative '../helpers/school_code_helper'
require_relative '../helpers/is_not_us'

# Error tracking. 
require 'airbrake'
require_relative '../config/initializers/airbrake'

#analytics
require 'mixpanel-ruby'

require_relative '../lib/workers'

require 'sinatra/flash'

class App < Sinatra::Base
  set :root, File.join(File.dirname(__FILE__), '../')
  register Sinatra::Flash

  require "sinatra/reloader" if development? 

  configure :development do
    register Sinatra::Reloader
  end

  configure :production do
    require 'newrelic_rpm'
    set :static_cache_control, [:public, :max_age => 600]
  end

  use Airbrake::Rack::Middleware

  #set mode (production or test)
  MODE ||= ENV['RACK_ENV']
  PRO  ||= "production"
  TEST ||= "test"

  tracker = Mixpanel::Tracker.new('358fa62873cd7120591bdc455b6098db')

  #########  ROUTES  #########

  # Admin authentication, from Sinatra.
  include RoutesHelper
  helpers RoutesHelper
  helpers SchoolCodeMatcher
  helpers TwilioTextingHelpers

  helpers do
    def base_url
      @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
    end
  end

  helpers IsNotUs

  enable :sessions unless test?
  set :session_secret, ENV['SESSION_SECRET']

  #root
  get '/' do
    case session[:role]
    when 'admin'
      redirect to '/dashboard/dashboard_admin'
    when 'teacher'
      redirect to '/dashboard/dashboard_teacher'
    else
      erb :'homepage/index', locals: {mixpanel_homepage_key: ENV['MIXPANEL_HOMEPAGE']}
    end 
  end

  get '/app' do
    erb :'pages/get-the-app'
  end

  get '/test' do
    "hi"
  end


  # texts user with link to download app 
  post '/get-app/send-app-link' do
    phone = params['phone']
    msg = "Download the Storytime app here: joinstorytime.com/app"
    MessageWorker.perform_async(msg, phone, STORYTIME_NO)
    return 200
  end


  get '/class' do
    redirect to '/'
  end


  get '/error' do
    halt erb :'register/error'
  end

  get '/privacy' do
    erb :'pages/privacy_policy'
  end

  get '/terms' do
    erb :'pages/terms'
  end

  get '/illustration-guide' do
    redirect to "https://docsend.com/view/vnndn8z"
  end 

  get '/poetry-guide' do
    redirect to "https://docsend.com/view/ij6bbnr"
  end 


  post '/success' do
    puts params.to_s  
    return params.to_s
  end

  post '/demo_success' do 
    notify_demo(params)
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

  get '/readup' do
    redirect to('https://invis.io/W3BCF5O2T#/229525683_Details')
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
    erb :'pages/resources'
  end

  get '/resources/' do 
    redirect to('/resources')
  end 

  # get '/team/?' do 
  #   erb :'pages/team'
  # end

  get '/case_study/?' do 
    erb :'pages/case_study'
  end

  # get '/join' do 
  #   erb :'pages/job_board'
  # end

  # get '/product_lead' do 
  #   erb :'pages/jobs/product'
  # end

  # get '/developer' do 
  #   erb :'pages/jobs/developer'
  # end 

  # get '/pilots' do 
  #   erb :'pages/jobs/pilots'
  # end 

  # get '/schools' do 
  #   erb :'pages/jobs/schools'
  # end 

  # get '/illustrator' do 
  #   erb :'pages/jobs/illustrator'
  # end 

  # get '/design' do 
  #   erb :'pages/jobs/design'
  # end 


  # redirect to Messenger app. 
  get '/books' do
    redirect to('http://m.me/490917624435792')
  end

  get '/rayna' do
    redirect to('https://www.youtube.com/watch?v=fjwSdLfkPOg&feature=youtu.be')
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

end
