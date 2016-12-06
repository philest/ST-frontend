#  app.rb                                     Phil Esterman     
# 
#  The routes controller. Uses helpers to reply to SMS. 
#  --------------------------------------------------------

#########  DEPENDENCIES  #########

#config the load path 
require 'bundler/setup'

#siantra dependencies 
require 'sinatra'
require "sinatra/reloader" if development?

#for access in views
require_relative '../config/initializers/aws'

#helpers
require_relative '../helpers/routes_helper'


set :root, File.join(File.dirname(__FILE__), '../')

require 'twilio-ruby'

configure :production do
  require 'newrelic_rpm'
  set :static_cache_control, [:public, :max_age => 600]
end

before do
  headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
  headers['Access-Control-Allow-Origin'] = "#{ENV['enroll_url']}"
  headers['Access-Control-Allow-Headers'] = 'accept, authorization, origin'
  headers['Access-Control-Allow-Credentials'] = 'true'
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

set :session_secret, "328479283uf923fu8932fu923uf9832f23f232"
enable :sessions

# use Rack::Session::Cookie, :key => 'rack.session',
                           # :path => '/',
                           # :secret => 'your_secret'

#root
get '/' do
  if session[:teacher]
    redirect to '/dashboard'
  elsif session[:admin]
    redirect to 'admin_dashboard'
  else
    erb :main_new
  end
end

get '/test_dashboard' do
  session[:admin] = { "id"=>1, "name"=>nil, "email"=>"david.mcpeek@yale.edu", "signature"=>"Mr. McPeek", "code"=>nil }
  session[:school] = {"id"=>39, "name"=>"Rocky Mountain Prep", "code"=>"RMP|RMP-es", "signature"=>"RMP"}
  get_url = ENV['RACK_ENV'] == 'production' ? ENV['enroll_url'] : 'http://localhost:5000'
  data = HTTParty.get("#{get_url}/teachers/#{session[:admin]['id']}")
  puts "data dashboard = #{data.body.inspect}"
  erb :admin_dashboard, :locals => {:teachers => JSON.parse(data)}
end




get '/user_exists' do
  puts "params=#{params}"

  res = HTTParty.get(
    "#{ENV['enroll_url']}/user_exists",
    query: {
      password: params['password'],
      email: params['email']
    }
  )
  puts res.inspect
  return res.parsed_response
end


get '/dashboard' do
  if session[:teacher].nil?
    redirect to '/'
  end
  puts "session[:teacher] = #{session[:teacher]}"

  get_url = ENV['RACK_ENV'] == 'production' ? ENV['enroll_url'] : 'http://localhost:5000'
  data = HTTParty.get("#{get_url}/users/#{session[:teacher]['id']}")
  puts "data dashboard = #{data.body.inspect}"

  erb :dashboard, :locals => {:users => JSON.parse(data)}
end

get '/admin_dashboard' do
  if session[:admin].nil?
    redirect to '/'
  end
  puts "session[:admin] = #{session[:admin]}"
  puts "session[:school] = #{session[:school]}"
  get_url = ENV['RACK_ENV'] == 'production' ? ENV['enroll_url'] : 'http://localhost:5000'
  data = HTTParty.get("#{get_url}/teachers/#{session[:admin]['id']}")
  puts "data dashboard = #{data.body.inspect}"
  erb :admin_dashboard, :locals => {:teachers => JSON.parse(data)}
end

get '/signup/spreadsheet' do
  if session[:teacher].nil?
    redirect to '/'
  end

  erb :spreadsheet
end

get '/logout' do
  session[:teacher] = nil
  session[:admin] = nil
  session[:school] = nil

  redirect to '/'
end

post '/signup/spreadsheet' do
  # Check if user uploaded a file
  if params['spreadsheet'] && params['spreadsheet'][:filename] && !session[:teacher].nil?
    filename = params['spreadsheet'][:filename]
    file = params['spreadsheet'][:tempfile]

    teacher_assets = S3.bucket('teacher-materials')
    if teacher_assets.exists?
      name = "teacher-uploads/#{session[:teacher]['signature']}/#{filename}"

      if teacher_assets.object(name).exists?
          puts "#{name} already exists in the bucket"
      else
        obj = teacher_assets.object(name)
        obj.put(body: file, acl: "public-read")
        puts "Uploaded '%s' to S3!" % name
      end
    end
    # dirname = "./public/uploads/#{session[:teacher]['signature']}"
    # unless File.directory?(dirname)
    #   FileUtils.mkdir_p(dirname)
    # end
    # path = "#{dirname}/#{filename}"

    # # Write file to disk
    # File.open(path, 'wb') do |f|
    #   f.write(file.read)
    # end
  end

  Pony.mail(:to => 'phil.esterman@yale.edu,david@joinstorytime.com',
            :cc => 'aubrey.wahl@yale.edu',
            :from => 'david.mcpeek@yale.edu',
            :subject => "ST: #{session[:teacher]['signature']} uploaded a spreadsheet",
            :body => "Check it out. #{filename}")
  flash[:spreadsheet] = "Congrats! We'll send your class a text in a few days."
  redirect to '/signup/spreadsheet'

end


# http://localhost:4567/signin?admin=david.mcpeek@yale.edu&school=rmp

get '/signin' do
  puts "signin params = #{params}"
  admin_email = params['admin']
  school_code = params['school']

  # admin = Admin.where(email: admin_email).first
  sig = HTTParty.get(
    "#{ENV['enroll_url']}/admin_sig",
    query: {
      email: admin_email
    }
  )
  puts "sig  = #{sig.inspect}"


  if sig.response.code.to_i == 404
    flash[:signin_error] = "Incorrect login information. Check with your administrator for the correct school code!"
    redirect to '/'
  end

  post_url = ENV['RACK_ENV'] == 'production' ? ENV['enroll_url'] : 'http://localhost:5000'
  puts "post_url = #{post_url}"
  data = HTTParty.post(
    "#{post_url}/signup", 
    body: {
      signature: sig,
      email: admin_email,
      password: school_code
    }
  )
  puts "data = #{data.code.inspect}"

  if data.code == 500 or data.code == 501
    flash[:signin_error] = "Incorrect login information. Check with your administrator for the correct school code!"
    redirect to '/'
    # return 
  end

  data = JSON.parse(data)

  puts data

  if data["secret"] != 'our little secret'
    flash[:signin_error] = "Incorrect login information. Check with your administrator for the correct school code!"
    redirect to '/'
  end

  # puts params
  session[:teacher] = data['teacher']
  session[:school]  = data['school']
  session[:users]   = data['users']
  session[:admin]   = data['admin']

  puts session.inspect

  redirect to '/signup'

end

 
# users sign in. posted from st-enroll.
post '/signin' do
  puts "params = #{params}"
  post_url = ENV['RACK_ENV'] == 'production' ? ENV['enroll_url'] : 'http://localhost:5000'
  puts "post_url = #{post_url}"
  data = HTTParty.post(
    "#{post_url}/signup", 
    body: params
  )
  puts "data = #{data.code.inspect}"

  if data.code == 500 or data.code == 501
    flash[:signin_error] = "Incorrect login information. Check with your administrator for the correct school code!"
    redirect to '/'
    # return 
    puts "ass me!!!!!!!"
  end

  data = JSON.parse(data)

  puts data

  if data["secret"] != 'our little secret'
    flash[:signin_error] = "Incorrect login information. Check with your administrator for the correct school code!"
    redirect to '/'
  end

  # puts params
  session[:teacher] = data['teacher']
  session[:school]  = data['school']
  session[:users]   = data['users']
  session[:admin]   = data['admin']

  puts session.inspect

  redirect to '/signup'
end


get '/signup' do
  if session[:teacher].nil? and session[:admin].nil?
    # maybe have a banner saying, "must log in through teacher account"
    flash[:signin_error] = "Incorrect login information. Check with your administrator for the correct school code!"
    redirect to '/'
  end

  if session[:admin]
    redirect to '/admin_dashboard'
  else
    redirect to '/dashboard'
  end

end



get '/privacy' do
  erb :privacy_policy
end




post '/success' do
  puts params.to_s  
  return params.to_s
end

# post '/success' do  
  # create_invite(params) 
  # erb :success
# end

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

post '/enroll_teachers_form_success' do
  puts "contact info params = #{params}"

  HTTParty.post(
    "#{ENV['enroll_url']}/invite_teachers",
    body: params
  )
  # Pony.mail(:to => 'supermcpeek@gmail.com',
  #           :cc => '',
  #           :from => 'supermcpeek@gmail.com',
  #           :subject => "An admin invited teachers",
  #           :body => "#{params}")

 

  flash[:teacher_invite_success] = "Congrats! We'll send your teachers an invitation to join StoryTime."
  redirect to '/admin_dashboard'
end

post '/enroll_families_form_success' do 

  enroll_families(params)
  erb :internal_success
end


get '/signup/flyer' do
  if session[:teacher].nil?
    redirect to '/'
  end

  erb :flyer
end

get '/signup/in-person' do
  if session[:teacher].nil?
    redirect to '/'
  end

  puts "session = #{session.inspect}"
  erb :inperson
end



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

