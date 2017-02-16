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

  enable :sessions unless test?
  set :session_secret, ENV['SESSION_SECRET']

  # use Rack::Session::Cookie, :key => 'rack.session',
  #                          :path => '/',
  #                          :secret => '328479283uf923fu8932fu923uf9832f23f232'

  #root
  get '/' do
    case session[:role]
    when 'admin'
      redirect to '/admin_dashboard'
    when 'teacher'
      redirect to '/dashboard'
    else
      erb :homepage, locals: {mixpanel_homepage_key: ENV['MIXPANEL_HOMEPAGE']}
    end 
  end

  get '/app' do
    erb :'get-the-app'
  end

  post '/get-app/send-app-link' do
    phone = params['phone']
    puts "in /get-app/send-app-link, phone = #{phone}"
    msg = "Download the Storytime app here: stbooks.org/app"
    MessageWorker.perform_async(msg, phone, STORYTIME_NO)
    return 200
  end

  # get '/test' do
  #   puts "params = #{params}"
  #   params['fun'] = "this is actually not very fun"
  #   puts "adjusted params = #{params}"
  #   # erb :test
  # end

  get '/test_dashboard' do
    session[:educator] = { "id"=>1, "name"=>nil, "email"=>"david.mcpeek@yale.edu", "signature"=>"Mr. McPeek", "code"=>nil }
    session[:role] = 'admin'
    session[:school] = {"id"=>39, "name"=>"Rocky Mountain Prep", "code"=>"RMP|RMP-es", "signature"=>"RMP"}
    get_url = ENV['RACK_ENV'] == 'production' ? ENV['enroll_url'] : 'http://localhost:4567/enroll'
    data = HTTParty.get("#{get_url}/teachers/#{session[:educator]['id']}")
    puts "data dashboard = #{data.body.inspect}"
    erb :admin_dashboard, :locals => {:teachers => JSON.parse(data)}
  end


  post '/freemium-signup-register' do
    require 'bcrypt'
    puts "in /freemium-signup-register new educator #{params} wants to sign up!"
    # STORE PASSWORD, NOT PASSWORD DIGEST

    plaintext_password = params['password']
    params['password'] = BCrypt::Password.create params['password']
    puts "in /freemium-signup-register new educator #{params} wants to sign up!"
    
    if params['first_name'].downcase != 'test' and (ENV['RACK_ENV'] != 'development')
      notify_admins("Educator joined freemium", params.to_s)
    end

    session[:first_name] = params['first_name']
    session[:last_name]  = params['last_name']
    session[:email]      = params['email']
    session[:password]   = plaintext_password

    redirect to "/freemium-signup"
  end

  get '/freemium-signup' do
    if [session[:first_name], session[:last_name], session[:email], session[:password]].include? nil or
       [session[:first_name], session[:last_name], session[:email], session[:password]].include? ''
       redirect to '/'
    end
    erb :'purple-modal-form', locals: {mixpanel_homepage_key: ENV['MIXPANEL_HOMEPAGE']}
  end

  # post '/freemium-signup' do
    # # {
    #   phone:,
    #   first_name:,
    #   last_name:,
    #   password:,
    #   class_code:,
    #   time_zone:,
    #   role:,
    # }
    # 
    # REMEMBER that we authenticate and create users in birdv, not here. 
    # if it's only a user, do that
    # 

    # goal: 
    # 
    # if USER:
    #   autheticate on birdv
    #   if response is 201, return 201
    #   
    # if TEACHER/ADMIN:
    #   create a user with login credentials for app, authenticate on birdv
    #   handle response if 201 or 404
    # 
  # end


  # QUESTIONS FOR AUBREY
    # HOW DO WE DO CLASS CODE??????? 
    # IS THERE A WAY TO DO WITHOUT?


  post '/freemium-signup' do
    # # {
    #   phone:,
    #   first_name:,
    #   last_name:,
    #   password:,
    #   class_code:,
    #   time_zone:,
    #   role:,
    # }
    # handle session data and email us with new info
    if [session[:first_name], session[:last_name], session[:email], session[:password]].include? nil or
       [session[:first_name], session[:last_name], session[:email], session[:password]].include? ''
       return 400
    end

    params['first_name'] = session[:first_name]
    params['last_name'] = session[:last_name]
    params['email'] = session[:email]
    params['password'] = session[:password]


    case params['role']
    when 'parent'
      puts "in freemium signup for parents with params=#{params} and session=#{session.inspect}"
      # check that teacher email is there

      # need phone in params....
      params['phone'] = params['email']

      # POST to birdv baby!!!!
      response = HTTParty.post(
                  ENV['birdv_url'] + '/api/auth/signup_free_agent',
                  body: params
                )
      # yyyyyyeaaeaaaah baby

      puts "response = #{response.inspect}"

      return response.code 

    when 'teacher', 'admin'
      puts "WE'RE DOING THE FREEMIUM THING FOR TEACHERS NOW!!!!!"
      # just add the school id as the value of the autocomplete
      # OOH and that way, if the value is empty, that means 
      # it doesn't exist in our db
      # 

      # we KNOW that if the teacher/admin is signing up for an existing school,
      # then we'll have the proper teacher/school code to give them
      # and their app experience will probably be like anyone in their class


      # what we DON'T KNOW is... what's the app experience for teachers who sign 
      # up and CREATE a school???
      # 
      # oh.... we don't need to worry about that right now....
      # 
      # 
      # first, we check to see if the school they indicated exists.............
      # how do we do that?
      # we have the 

      puts "in freemium signup for teachers/admin with params=#{params} and session=#{session.inspect}"

      if session[:first_name].downcase != 'test' and (ENV['RACK_ENV'] != 'development')
        # don't send the actual password! 
        notify_params = {
          first_name: params['first_name'],
          last_name: params['last_name'],
          email: params['email'],
          phone: params['email']
        }
        notify_admins("#{params['role']} finished freemium signup", notify_params.to_s)
      end

      begin
        # get the school id! 
        school_id = params['school_id'].to_i

        school = School.where(id: school_id).first 

        puts "HERE'S OUR SCHOOL BROOOO!!!! #{school.inspect}"

        password_digest = BCrypt::Password.create params['password']

        # FOR BOTH FIND-SCHOOL AUTOCOMPLETE AND ADD-SCHOOL,
        # NEED TO HAVE ALL THESE PARAMS!!
        # so add params to autocomplete.....
        # but you don't need to worry about this now, 
        # because for now the only way to add schools is through 
        # the add-school form, which requires all these elements.
        # so do this tomorrow.

        new_school = false

        if school.nil?

          new_school = true

          # this school doesn't exist bro!
          # will need to create it! 
          puts "THIS SCHOOL DOESN'T FUCKING EXIST BRO!!!!!!!!"

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

        # create teacher/admin
        educator_info = {
          signature: params['signature'],
          first_name: params['first_name'],
          last_name: params['last_name'],
          email: params['email'],
          phone: params['email'],
          password_digest: password_digest
        }

        if params['role'] == 'teacher'
          # am i overwriting anything here?
          puts "i'm a teacher, look at MEEEEEEE"
          educator = Teacher.where(email: params['email']).or(phone: params['email']).first 
          # if the teacher already exists, don't do JACK SHIT!!!!!
          if educator.nil?

            educator = Teacher.create(educator_info)

            school.signup_teacher(educator)

            FlyerWorker.perform_async(educator.id, school.id) # if new_signup

            # SHOULD I SEND A WELCOME EMAIL TO THAT TEACHER?

            params['class_code'] = educator.code.split('|').first

            # need phone in params....
            params['phone'] = params['email']

            # POST to birdv baby!!!! create that fucking USER!!!!!!!!s 
            response = HTTParty.post(
              ENV['birdv_url'] + '/api/auth/signup',
              body: params
            )
            puts "response = #{response.inspect}"

            # yyyyyyeaaeaaaah baby
          end

          # and THEN create the user!
          # with the correct class code the way you normally would!!!!!!!!!
        else
          puts "I'M AN ADMIN YO!"
          educator = Admin.where(email: params['email']).or(phone: params['email']).first 
          if educator.nil?
            educator = Admin.where(educator_info).first || Admin.create(educator_info)
            school.add_admin(educator)

            params['class_code'] = school.code.split('|').first

            # need phone in params....
            params['phone'] = params['email']

            # POST to birdv baby!!!! create that fucking USER!!!!!!!!s 
            response = HTTParty.post(
              ENV['birdv_url'] + '/api/auth/signup',
              body: params
            )

            puts "response = #{response.inspect}"
            # yyyyyyeaaeaaaah baby
          end

        end

        if new_school
          # we just don't want peeps signing into their dashboard.
          # so we send them an invalid code in case they wander
          # to the page7 modal
          return 'invalid_code'
        else
          return school.code.split('|').first
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
    if session[:educator].nil?
      redirect to '/'
    end
    puts "session[:educator] = #{session[:educator]}"

    get_url = ENV['RACK_ENV'] == 'production' ? ENV['enroll_url'] : 'http://localhost:4567/enroll'
    data = HTTParty.get("#{get_url}/users/#{session[:educator]['id']}")
    puts "data dashboard = #{data.body.inspect}"

    erb :dashboard, :locals => {:users => JSON.parse(data)}
  end


  get '/admin_dashboard' do
    if session[:educator].nil?
      redirect to '/'
    end
    puts "session[:educator] = #{session[:educator]}"
    puts "session[:school] = #{session[:school]}"
    get_url = ENV['RACK_ENV'] == 'production' ? ENV['enroll_url'] : 'http://localhost:4567/enroll'
    data = HTTParty.get("#{get_url}/teachers/#{session[:educator]['id']}")
    puts "data dashboard = #{data.body.inspect}"
    if data.body != "[]"
      puts "normal admin dashboard"
      erb :admin_dashboard, :locals => {:teachers => JSON.parse(data), school_users: nil}
    else # this is a school with no teachers....
      # so check for students
      get_url = ENV['RACK_ENV'] == 'production' ? ENV['enroll_url'] : 'http://localhost:4567/enroll'
      data = HTTParty.get("#{get_url}/school/users/#{session[:educator]['id']}")
      puts "data_dashboard2.0 = #{data.body.inspect}"
      puts "data = #{JSON.parse(data)}"
      if data != "" # go to the SPECIAL school_dashboard
        # process locals somehow.........
        puts "user admin dashboard"
        erb :admin_dashboard, :locals => {:school_users => JSON.parse(data)}
      else # regular admin dashboard with no teachers...... :(
        puts "normal admin dashboard"
        erb :admin_dashboard, :locals => {:teachers => JSON.parse(data), school_users: nil}
      end
    end
  end

  get '/signup/spreadsheet' do
    if session[:educator].nil?
      redirect to '/'
    end

    erb :spreadsheet
  end

  get '/logout' do
    session[:educator] = nil
    session[:school] = nil
    session[:role] = nil

    redirect to '/'
  end

  post '/signup/spreadsheet' do
    # Check if user uploaded a file
    if params['spreadsheet'] && params['spreadsheet'][:filename] && !session[:educator].nil?
      filename = params['spreadsheet'][:filename]
      file = params['spreadsheet'][:tempfile]

      teacher_assets = S3.bucket('teacher-materials')
      if teacher_assets.exists?
        name = "teacher-uploads/#{session[:educator]['signature']}/#{filename}"

        if teacher_assets.object(name).exists?
            puts "#{name} already exists in the bucket"
        else
          obj = teacher_assets.object(name)
          obj.put(body: file, acl: "public-read")
          puts "Uploaded '%s' to S3!" % name
        end
      end
      # dirname = "./public/uploads/#{session[:educator]['signature']}"
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
              :subject => "ST: #{session[:educator]['signature']} uploaded a spreadsheet",
              :body => "Check it out. #{filename}")
    flash[:spreadsheet] = "Congrats! We'll send your class a text in a few days."
    redirect to '/signup/spreadsheet'

  end


  # http://localhost:4567/signin?admin=david.mcpeek@yale.edu&school=rmp
  # 
  # http://localhost:4567/signin?email=david.mcpeek@yale.edu&school=rmp&name=David+McPeek
  # 
  # http://joinstorytime.com/signin?school=rmp&email=aperricone@rockymountainprep.org&name='Mrs. Perricone'

  # need to update this for new roles.....
  # need to have a role parameter
  # 
  get '/signin' do
    puts "signin params = #{params}"
    school_code = params['school']
    email       = params['email']
    signature   = params['name']
    role        = params['role']
    first_name  = params['first_name']
    last_name   = params['last_name']

    if params['admin'] == 'james@rockymountainprep.org'
      signature, email, role = 'James Cryan', 'james@rockymountainprep.org', 'admin'
    elsif params['admin'] == 'athompson@rockymountainprep.org'
      signature, email, role = 'Angelin Thompson', 'athompson@rockymountainprep.org', 'admin'
    elsif params['email'].include? 'rockymountainprep' 
      # everyone else at RMP's a teacher
      role = 'teacher'
    end

    post_url = ENV['RACK_ENV'] == 'production' ? ENV['enroll_url'] : 'http://localhost:4567/enroll'
    puts "post_url = #{post_url}"
    data = HTTParty.post(
      "#{post_url}/signup", 
      body: {
        signature: signature,
        email: email,
        password: school_code,
        role: role,
        first_name: first_name,
        last_name: last_name
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
    session[:educator] = data['educator']
    # session[:educator]  = data['teacher']
    session[:school]   = data['school']
    session[:users]    = data['users']
    session[:role]     = data['role']
    # session[:educator]    = data['admin']

    puts session.inspect

    if session['educator'].nil?
      # maybe have a banner saying, "must log in through teacher account"
      flash[:signin_error] = "Incorrect login information. Check with your administrator for the correct school code!"
      redirect to '/'
    end

    case session['role']
    when 'admin'
      puts "going to admin dashboard"
      if params['invite']
        redirect to '/admin_dashboard?invite=' + params['invite']
      else
        redirect to '/admin_dashboard'
      end


      redirect to '/admin_dashboard'
    when 'teacher'
      puts "going to teacher dashboard"
      if params['flyers']
        redirect to '/dashboard?flyers=' + params['flyers']
      else
        redirect to '/dashboard'
      end
    end

  end

   
  # users sign in. posted from st-enroll.
  post '/signin' do
    puts "params = #{params}"
    post_url = ENV['RACK_ENV'] == 'production' ? ENV['enroll_url'] : 'http://localhost:4567/enroll'
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
    session[:educator] = data['educator']
    session[:school]  = data['school']
    session[:users]   = data['users']
    # session[:educator]   = data['admin']
    session[:role]    = data['role']

    puts session.inspect

    # redirect to '/signup'

    if session['educator'].nil?
      # maybe have a banner saying, "must log in through teacher account"
      flash[:signin_error] = "Incorrect login information. Check with your administrator for the correct school code!"
      redirect to '/'
    end

    case session['role']
    when 'admin'
      puts "going to admin dashboard"

      if params['invite']
        redirect to '/admin_dashboard?invite=' + params['invite']
      else
        redirect to '/admin_dashboard'
      end

    when 'teacher'
      puts "going to teacher dashboard"
      if params['flyers']
        redirect to '/dashboard?flyers=' + params['flyers']
      else
        redirect to '/dashboard'
      end
    end

  end

  get '/class' do
    redirect to '/'
  end


  get '/error' do
    halt erb :error 
  end


  get '/signup' do
    if session['educator'].nil?
      # maybe have a banner saying, "must log in through teacher account"
      flash[:signin_error] = "Incorrect login information. Check with your administrator for the correct school code!"
      redirect to '/'
    end

    case session['role']
    when 'admin'
      puts "going to admin dashboard"

      if params['invite']
        redirect to '/admin_dashboard?invite=' + params['invite']
      else
        redirect to '/admin_dashboard'
      end

    when 'teacher'
      puts "going to teacher dashboard"
      if params['flyers']
        redirect to '/dashboard?flyers=' + params['flyers']
      else
        redirect to '/dashboard'
      end

    end
  end


  get '/privacy' do
    erb :privacy_policy
  end

  get '/terms' do
    erb :terms
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

  # get '/:code/class' do
  #   erb :maintenance
  # end
  get '/coming-soon' do
    puts "params = #{params}"
    puts "session = #{session.inspect}"

    text = {}
    case session[:locale]
    when 'es'
      text[:exclaim] = "¡Muy bien!"
      text[:header] = "empieza pronto!"
      text[:return] = "Le enviaremos un mensaje de texto"
      text[:weekday] = "el jueves"
      text[:date] = "4 de enero para empezar!"
      text[:info] = "Le envíaremos un texto pronto con los libros de #{session[:teacher_sig]}" 

      text[:subtitle] = "Consigue libros gratis de #{session[:teacher_sig]} directamente en su celular"
    else
      text[:exclaim] = "Great!"
      text[:header] = "starts soon!"
      text[:return] = "We will text you on"
      text[:weekday] = "Thursday"
      text[:date] = "January 4th to start!"
      text[:info] = "We'll text you in a few days with #{session[:teacher_sig]}'s books!"


      text[:subtitle] = "Get free books from #{session[:teacher_sig]} right on your phone"

    end

    # erb :'get-app', locals: {school: session[:school_sig], teacher: session[:teacher_sig], text: text}
    # erb :maintenance, locals: {school: session[:school_sig], text: text}

    erb :maintenance, locals: {school: session[:school_sig], teacher: session[:teacher_sig], text: text}
  end


  get '/list-of-schools' do
    blacklist = [
      'StoryTime', 
      'Freemium', 
      'Freemium School',
      'ST Elementary'
    ]

    regex = "%#{params['term']}%"

    puts "regex = #{regex}"

    School.where(signature: blacklist).invert
          .where(Sequel.ilike(:signature, regex)).map do |school|
      location = ''
      puts "school vals = #{school.city}, #{school.state}"
      if school.city and school.state
        puts "1"
        location = "#{school.city}, #{school.state}"
      elsif school.city
        puts "2"
        location = "#{school.city}"
      elsif school.state
        puts "3"
        location = "#{school.state}"
      end
      {
        label: school.signature,
        value: school.id,
        desc: location,
        city: school.city,
        state: school.state
      }
    end.to_json
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

  get '/team/?' do 
    erb :team
  end

  get '/case_study/?' do 
    erb :case_study
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

    Pony.mail(:to => 'phil.esterman@yale.edu,supermcpeek@gmail.com,aawahl@gmail.com',
                :from => 'david@joinstorytime.com',
                :headers => { 'Content-Type' => 'text/html' },
                :subject => "An admin #{params['admin_sig']} from #{params['school_sig']} invited teachers",
                :body => params)
   

    flash[:teacher_invite_success] = "Congrats! We'll send your teachers an invitation to join StoryTime."
    session[:educator]['signin_count'] += 1

    redirect to '/admin_dashboard'
  end

  get '/teacher/visited_page' do
    puts "visited page session = #{session.inspect}"
    puts "in visited page"
    session[:educator]['signin_count'] += 1
    status 200
    return session[:educator]['signin_count'].to_s
  end


  get '/reset' do
    session[:educator]['signin_count'] = 0
    status 200
    return session[:educator]['signin_count'].to_s
  end

  post '/enroll_families_form_success' do 
    puts "params = #{params}"

    puts "session = #{session.inspect}"

    teacher = Teacher.where(id: session['educator']['id']).first
    if teacher.nil?
      return 404
    end

    25.times do |idx| # TODO: this loop is shit
      
      if ![nil, ''].include? params["phone_#{idx}"]
        phone_num   = params["phone_#{idx}"]
        child_name  = params["name_#{idx}"]
      else 
        next      
      end

      # TODO some day: when insertion fails, let teacher know that parent already exists
      # and that if they click confirm, they may be changing the kid's number (make this
      # happen in seperate worker?)
      begin
        # I sure hope the phone number made it in!
        parent = User.where(phone: phone_num).first

        # create new parent if didn't already exists
        if parent.nil? then 
          parent = User.create(:phone => phone_num, platform: 'app')
          parent.state_table.update(subscribed?: false)
          # parent.state_table.update(story_number: 0)
        else # parent exists
          # we don't want to send them multiple texts.....
          puts "parent already exists, don't send them a text plz....."
          next 
        end

        # update parent's student name
        if not child_name.nil? then parent.update(:child_name => child_name) end

        # add parent to teacher!
        teacher.signup_user(parent)
        puts "added #{parent.child_name if not params["name_#{idx}"].nil?}, phone => #{parent.phone}"


        # issue the text messages
        preschooler = child_name.split.first
        msg = "Hi it's #{teacher.school.signature}! #{teacher.signature} is using StoryTime to send free books for #{preschooler}.\n\nGet it at stbooks.org/#{teacher.code.split('|').first}"
        MessageWorker.perform_async(msg, phone_num, STORYTIME_NO)
      
      rescue Sequel::Error => e
        puts e.message
      end     
    end



    # Report new enrollees.
    Pony.mail(:to => 'phil.esterman@yale.edu',
          :cc => 'david.mcpeek@yale.edu',
          :from => 'phil.esterman@yale.edu',
          :subject => "ST: A new teacher (#{params[:teacher_signature]}) enrolled \
                         #{(params.count / 2)-1} student.",
          :body => "They enrolled: \
                    #{params}.")
    # flash[:notice] = "Great! Your class was successfully added."

    return 200

  end


  get '/signup/flyer' do
    if session[:educator].nil?
      redirect to '/'
    end

    erb :flyer
  end

  get '/signup/in-person' do
    if session[:educator].nil?
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

end
