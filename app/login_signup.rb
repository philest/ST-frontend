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

# Error tracking. 
require 'airbrake'
require_relative '../config/initializers/airbrake'

#analytics
require 'mixpanel-ruby'

require_relative '../lib/workers'

require 'sinatra/flash'

class LoginSignup < Sinatra::Base
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

    def root
      '../'
    end

  end

  helpers IsNotUs

  enable :sessions unless test?
  set :session_secret, ENV['SESSION_SECRET']

  helpers do 
    # attemps to login in the teacher or admin based on the provided params.
    def loginAttempt(params)
      username    = params[:username]
      password    = params[:password]
      role        = params[:role]

      # instead of a plaintext password, params may include
      # the hashed password_digest instead. 
      # this method can work with both.
      if not params[:digest].nil? and not params[:digest].empty?
        password = params[:password] = params[:digest]
      end

      # if missing any params, return 500
      if username.nil? or password.nil? or username.empty? or password.empty? 
        txt = "username: #{username.inspect}, Password: #{password.inspect}"

        missing = []
        missing << "username" if (username.nil? or username.empty?)
        missing << "password" if (password.nil? or password.empty?)

        notify_admins("A teacher failed to sign in to their account - missing #{missing}", txt)
        return 500
      end

      # educator = the teacher/admin in question.
      case role
      when 'admin'
        educator = Admin.where_username_is(username)
      when 'teacher'
        educator = Teacher.where_username_is(username)
      else
        educator = Admin.where_username_is(username)
        if educator.nil?
          educator = Teacher.where_username_is(username)
          role = 'teacher'
        else
          role = 'admin'
        end
      end


      if educator.nil?
        # never existed
        return 500
      end

      if educator.grade.nil? or educator.grade > 3 # kindergarten
        # not the right grade!
        if educator.is_not_us
          notify_admins("educator id=#{educator.id} of grade #{educator.grade.inspect} was refused access to the dashboard because they don't teach prek")
        end
        return 305
      end

      school = educator.school

      # if the PASSWORD DIGEST was provided, authenticate it. 
      if not params[:digest].nil? and not params[:digest].empty?
        if educator.password_digest != params[:digest]
          puts "incorrect password digest lol"
          return 500
        end
      # else if the PLAINTEXT PASSWORD was provided, authenticate it. 
      else
        if educator.authenticate(password) == false
          # wrong password!
          puts "incorrect password! lol"
          return 500
        end
      end

      if role == 'teacher'
        FlyerWorker.perform_async(educator.id, school.id) # if new_signup
      end

      # get school/educator metadata.
      educator_hash = educator.to_hash.select {|k, v| [:id, :name, :signature, :email, :phone, :code, :t_number, :signin_count].include? k}
      school_hash   = school.to_hash.select {|k, v| [:id, :name, :signature, :code].include? k }

      unless password.downcase == 'test' or password.downcase == 'read' or ENV['RACK_ENV'] == 'development'
        email_admins("#{role.capitalize} #{educator.signature} at #{school.signature} signed into their account")
      end

      # status 200

      # the educator is signing in, so increment the signin_count
      educator.update(signin_count: educator.signin_count + 1)

      return {
        educator: educator_hash,
        school: school_hash,
        secret: 'our little secret',
        role: role
      }.to_json
    end

  end

  #########  ROUTES  #########

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


  # the signin route used for teacher/admin dashboard quicklinks.
  get '/signin' do
    puts "signin params = #{params}"

    password_digest = params['digest']
    username        = params['username']
    role            = params['role']

    if !params['email'].nil? and !params['email'].empty?
      params['username'] = params['email']
    end


    data = loginAttempt({
      digest: params['digest'],
      username: params['username'],
      role: params['role']
    })


    if data == 500 or data == 501
      flash[:signin_error] = "Incorrect login information. Check with your administrator for the correct school code!"
      redirect to '/'
      # return 
    end

    if data == 303
      flash[:freemium_permission_error] = "We'll have your free StoryTime profile ready for you soon!"
      redirect '/'
    end

    if data == 305
      flash[:wrong_grade_level_error] = "Right now, Storytime is only available for preschool. We'll email you when it's ready for your grade level!"
      redirect '/'
    end

    data = JSON.parse(data)

    # have some secret to make sure this is coming from our server.
    if data["secret"] != 'our little secret'
      flash[:signin_error] = "Incorrect login information. Check with your administrator for the correct school code!"
      redirect to '/'
    end

    # puts params
    session[:educator] = data['educator']
    session[:school]   = data['school']
    session[:role]     = data['role']
    session[:users]    = data['users']


    if session['educator'].nil?
      # maybe have a banner saying, "must log in through teacher account"
      flash[:signin_error] = "Incorrect login information. Check with your administrator for the correct school code!"
      redirect to '/'
    end

    case session['role']
    when 'admin'
      # automatically open the invite-teachers modal with the invite parameter.
      if params['invite']
        redirect to root + 'dashboard/admin_dashboard?invite=' + params['invite']
      else
        redirect to root + 'dashboard/admin_dashboard'
      end
      redirect to root + 'dashboard/admin_dashboard'
    when 'teacher'
      # automatically open the invite-flyers modal with the flyers parameter.
      if params['flyers']
        redirect to root + 'dashboard/dashboard?flyers=' + params['flyers']
      else
        redirect to root + 'dashboard/dashboard'
      end
    end

  end

   
  # the normal signin route used from the homepage.
  post '/signin' do
    post_url = ENV['RACK_ENV'] == 'production' ? ENV['enroll_url'] : 'http://localhost:4567/auth/enroll'
    data = loginAttempt(params)

    if data == 500 or data == 501
      flash[:signin_error] = "Incorrect login information. Check with your administrator for the correct school code!"
      redirect to '/'
      # return 
      puts "ass me!!!!!!!"
    end

    if data == 303
      flash[:freemium_permission_error] = "We'll have your free StoryTime profile ready for you soon!"
      redirect '/'
    end

    if data == 305
      flash[:wrong_grade_level_error] = "Right now, Storytime is only available for preschool. We'll email you when it's ready for your grade level!"
      redirect '/'
    end

    data = JSON.parse(data)

    # have some secret to make sure this is coming from our server.
    if data["secret"] != 'our little secret'
      flash[:signin_error] = "Incorrect login information. Check with your administrator for the correct school code!"
      redirect to '/'
    end

    # puts params
    session[:educator] = data['educator']
    session[:school]  = data['school']
    session[:users]   = data['users']
    session[:role]    = data['role']


    if session['educator'].nil?
      # maybe have a banner saying, "must log in through teacher account"
      flash[:signin_error] = "Incorrect login information. Check with your administrator for the correct school code!"
      redirect to '/'
    end

    case session['role']
    when 'admin'
      # automatically open the invite-teachers modal with the invite parameter.
      if params['invite']
        redirect to root + 'dashboard/admin_dashboard?invite=' + params['invite']
      else
        redirect to root + 'dashboard/admin_dashboard'
      end

    when 'teacher'
      # automatically open the invite-flyers modal with the flyers parameter.
      if params['flyers']
        redirect to root + 'dashboard/dashboard?flyers=' + params['flyers']
      else
        redirect to root + 'dashboard/dashboard'
      end
    end

  end

  get '/signup' do
    if session['educator'].nil?
      # maybe have a banner saying, "must log in through teacher account"
      flash[:signin_error] = "Incorrect login information. Check with your administrator for the correct school code!"
      redirect to '/'
    end

    case session['role']
    when 'admin'
      # automatically open the invite-teachers modal with the invite parameter.
      if params['invite']
        redirect to root + 'dashboard/admin_dashboard?invite=' + params['invite']
      else
        redirect to root + 'dashboard/admin_dashboard'
      end

    when 'teacher'
      # automatically open the invite-flyers modal with the flyers parameter.
      if params['flyers']
        redirect to root + 'dashboard/dashboard?flyers=' + params['flyers']
      else
        redirect to root + 'dashboard/dashboard'
      end

    end
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