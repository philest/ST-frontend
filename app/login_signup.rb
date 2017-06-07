#  login_signup.rb          Phil Esterman, David McPeek, Aubrey Wahl     
# 
#  The login/signup controller for teachers and admin.
#  The authentication entrypoint to the dashboards.
#  
#  *Also enable users to signup for a free trial.*
#  --------------------------------------------------------

#########  DEPENDENCIES  #########
#
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
require_relative '../helpers/login_attempt'

# Error tracking. 
require 'airbrake'
require_relative '../config/initializers/airbrake'

#analytics
require 'mixpanel-ruby'

require_relative '../lib/workers'

require 'sinatra/flash'



class LoginSignup < Sinatra::Base
  # sets root as the parent-directory of the current file
  set :root, File.join(File.dirname(__FILE__), '../')
  # sets the view directory correctly
  set :views, Proc.new { File.join(root, "views") }
  
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
  helpers IsNotUs
  helpers LoginAttempt # has the loginAttempt() method

  helpers do
    def base_url
      @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
    end

    def root
      '../'
    end

  end

  enable :sessions unless test?
  set :session_secret, ENV['SESSION_SECRET']


  #########  ROUTES  #########

  # the signin route used for teacher/admin dashboard quicklinks.
  get '/signin' do
    loginAttempt(params)
  end

  # the normal signin route used from the homepage.
  post '/signin' do
    loginAttempt(params)
  end


  # stores the POST information from the homepage into the session.
  # this is the entrypoint to the purple-modals page from the homepage. 
  # the params contain data that the user inputs from the homepage
  #   to begin signing up.
  post '/freemium-signup-register' do
    require 'bcrypt'

    # STORE PASSWORD, NOT PASSWORD DIGEST
    plaintext_password = params['password']
    params['password_digest'] = BCrypt::Password.create params['password']
    
    # delete the plaintext password so we're not sending it over HTTP (security reasons)
    params.delete 'password'

    if is_not_us?(params['first_name']) and is_not_us?(params['username']) and is_not_us?(plaintext_password) and is_not_us?(params['last_name'])
      notify_admins("Someone joined freemium", params.to_s)
    end

    session[:first_name] = params['first_name']
    session[:last_name]  = params['last_name']
    session[:username]   = params['username']
    session[:password]   = plaintext_password

    redirect to "/freemium-signup"
  end

  # get the index page for the purple-signup-modals.
  get '/freemium-signup' do
    if [session[:first_name], session[:last_name], session[:username], session[:password]].include? nil or
       [session[:first_name], session[:last_name], session[:username], session[:password]].include? ''
       redirect to '/'
    end
    erb :'signup/index', locals: {mixpanel_homepage_key: ENV['MIXPANEL_HOMEPAGE']}
  end


  # If all is successful, creates a freemium
  # 1. teacher 
  # 2. admin
  # 3. or user
  # depending on params['role']
  # 
  # This route is used by the purple-modals signup page. 
  # 
  post '/freemium-signup' do

    # handle session data and email us with new info
    if [session[:first_name], session[:last_name], session[:username], session[:password]].include? nil or
       [session[:first_name], session[:last_name], session[:username], session[:password]].include? ''
       return 400
    end

    params['first_name'] = session[:first_name]
    params['last_name'] = session[:last_name]
    params['username'] = session[:username]
    params['password'] = session[:password]


    case params['role']
    when 'parent'
      # check that teacher email is there

      # POST to birdv 
      response = HTTParty.post(
                  ENV['birdv_url'] + '/api/auth/signup_free_agent',
                  body: params
                )

      return response.code 

    when 'teacher', 'admin'

      begin
        # get the school id! 
        school_id = params['school_id'].to_i

        school = School.where(id: school_id).first 

        password_digest = BCrypt::Password.create params['password']

        # variable to determine whether we're creating a new school in our database
        new_school = false

        if school.nil?

          new_school = true

          # this school doesn't exist bro!
          # we'll need to create it! 

          # create a school with a free_ass_class_code
          free_ass_class_code = "#{params['school_name']}_#{params['school_city']}_#{params['school_state']}"
          school_info = {
            signature: params['school_name'],
            name: params['school_name'],
            city: params['school_city'],
            state: params['school_state'],
            code: "#{free_ass_class_code}|#{free_ass_class_code}-es",
            plan: 'free'
          }

          school = School.where(school_info).first || School.create(school_info)
        
        end # if school.nil? 

        # otherwise, school is not nil

        # create teacher/admin
        educator_info = {
          signature: params['signature'],
          first_name: params['first_name'],
          last_name: params['last_name'],
          password_digest: password_digest,
          grade: params['classroom_grade'].to_i
        }

        if session[:username].is_email?
          contactType = 'email'
        elsif session[:username].is_phone?
          contactType = 'phone'
        else
          return 401 # for invalid username/phone/email
        end

        educator_info[contactType] = session[:username]

        if params['role'] == 'teacher'

          educator = Teacher.where_username_is(session[:username])
          
          # if the educator doesn't exist yet, create them! 
          if educator.nil?

            educator = Teacher.create(educator_info)

            school.signup_teacher(educator)

            FlyerWorker.perform_async(educator.id, school.id) # if new_signup

            if new_school == false
              if !educator.email.nil?
                # send a welcome email to that teacher
                WelcomeTeacherWorker.perform_async(educator.id) 
              end

            end

            params['class_code'] = educator.code.split('|').first


            # POST to birdv baby!!!! create that fucking USER!!!!!!!!
            response = HTTParty.post(
              ENV['birdv_url'] + '/api/auth/signup',
              body: params
            )

            # yyyyyyeaaeaaaah baby

          else
            # if the teacher already exists, don't do JACK SHIT!!!!!
            puts "this teacher already exists...."
          end

          # and THEN create the user!
          # with the correct class code the way you normally would!!!!!!!!!
        else # ADMIN!

          educator = Admin.where_username_is(session[:username])
          if educator.nil?
            educator = Admin.create(educator_info)
            school.add_admin(educator)

            params['class_code'] = school.code.split('|').first

            if new_school == false
              if !educator.email.nil?
                WelcomeAdminWorker.perform_async(educator.id)
              end
            end


            # POST to birdv baby!!!! create that fucking USER!!!!!!!! 
            # for the admin.
            response = HTTParty.post(
              ENV['birdv_url'] + '/api/auth/signup',
              body: params
            )

            # yyyyyyeaaeaaaah baby
          end

        end

        if is_not_us?(session[:first_name]) and is_not_us?(session[:username]) and is_not_us?(session[:last_name])
          # don't send the actual password! 
          # 
          # CHANGE THIS SHIT
          notify_params = {
            first_name: session[:first_name],
            last_name: session[:last_name],
            username: session[:username],
            params: params.to_s
          }

          notify_admins("#{params['role']} finished freemium signup", notify_params.to_s)
        end

        if new_school
          # we just don't want peeps signing into their dashboard.
          # so we send them an invalid code in case they wander
          # to the page7 modal
          return 'invalid_code'
        else
          return 'valid_code'
        end

      
      rescue => e
        p e.message
        puts "returning 404, i guess"
        return 404
      end
        # # maybe do server-side processing to figure out if it's an email or phone....
        # # could also try this on the client side and update the input name. validations.
    else
      puts "failure, missing some params. params=#{params} and session=#{session.inspect}"
      return 400
      # redirect to '/'
    end

    puts "returning 200, i guess"
    return 200
  end

  get '/user_exists' do
    puts "params=#{params}"

    if params['username'].nil? or params['username'].empty?
      return 404
    end

    exists = Teacher.where_username_is(params['username'])
    exists ||= Admin.where_username_is(params['username'])

    if exists
      return 200
    else
      return 404
    end

  end

  get '/logout' do
    session[:educator] = nil
    session[:school] = nil
    session[:role] = nil

    redirect to root
  end


  # used for the school search bar in the freemium-signup page.
  get '/list-of-schools' do
    blacklist = [
      'StoryTime', 
      'Freemium', 
      'Freemium School',
      'ST Elementary'
    ]

    regex = "%#{params['term']}%"

    # only send the first 50 results, let's say
    matching_schools = FreemiumSchool.where(Sequel.ilike(:signature, regex))
                                        .limit(50).map do |school|

      location = ''
      if school.city and school.state
        location = "#{school.city}, #{school.state}"
      elsif school.city
        location = "#{school.city}"
      elsif school.state
        location = "#{school.state}"
      end

      {
        label: school.signature,
        value: 'free_school_value',
        desc: location,
        city: school.city,
        state: school.state
      }

    end


    matching_schools += School.where(Sequel.ilike(:signature, regex)).map do |school|
      location = ''
      if school.city and school.state
        location = "#{school.city}, #{school.state}"
      elsif school.city
        location = "#{school.city}"
      elsif school.state
        location = "#{school.state}"
      end
      {
        label: school.signature,
        value: school.id,
        desc: location,
        city: school.city,
        state: school.state
      }
    end 
    # THE DEVIL IS ALIVE! 
    matching_schools.to_json

  end





                          

end # class LoginSignup