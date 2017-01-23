#  app.rb                                     Phil Esterman     
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

  # before do
  #   headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
  #   headers['Access-Control-Allow-Origin'] = "#{ENV['enroll_url']}"
  #   headers['Access-Control-Allow-Headers'] = 'accept, authorization, origin'
  #   headers['Access-Control-Allow-Credentials'] = 'true'
  # end

  use Airbrake::Rack::Middleware

  #set mode (production or test)
  MODE ||= ENV['RACK_ENV']
  PRO ||= "production"
  TEST ||= "test"

  tracker = Mixpanel::Tracker.new('358fa62873cd7120591bdc455b6098db')

  #########  ROUTES  #########

  # Admin authentication, from Sinatra.
  include RoutesHelper
  helpers RoutesHelper
  helpers SchoolCodeMatcher
  helpers TwilioTextingHelpers

  enable :sessions
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
    params['password'] = BCrypt::Password.create params['password']
    puts "in /freemium-signup-register new educator #{params} wants to sign up!"
    

    if params['first_name'].downcase != 'test' and (ENV['RACK_ENV'] != 'development')
      notify_admins("Educator joined freemium", params.to_s)
    end

    session[:first_name] = params['first_name']
    session[:last_name]  = params['last_name']
    session[:email]      = params['email']
    session[:password_digest]   = params['password']

    redirect to "/freemium-signup"
  end

  get '/freemium-signup' do
    if [session[:first_name], session[:last_name], session[:email], session[:password_digest]].include? nil or
       [session[:first_name], session[:last_name], session[:email], session[:password_digest]].include? ''
       redirect to '/'
    end
    
    erb :'purple-modal-form', locals: {mixpanel_homepage_key: ENV['MIXPANEL_HOMEPAGE']}
  end


  post '/freemium-signup' do
    # handle session data and email us with new info
    if [session[:first_name], session[:last_name], session[:email], session[:password_digest]].include? nil or
       [session[:first_name], session[:last_name], session[:email], session[:password_digest]].include? ''
       redirect to '/'
    end

    params['first_name'] = session[:first_name]
    params['last_name'] = session[:last_name]
    params['email'] = session[:email]
    params['password_digest'] = session[:password_digest]

    case params['role']
    when 'parent'
      puts "in freemium signup for parents with params=#{params} and session=#{session.inspect}"
      # check that teacher email is there

      if session[:first_name].downcase != 'test' and (ENV['RACK_ENV'] != 'development')
        notify_admins("Parent finished freemium signup", params.to_s)
      end

    when 'teacher', 'admin'
      puts "in freemium signup for teachers/admin with params=#{params} and session=#{session.inspect}"

      if session[:first_name].downcase != 'test' and (ENV['RACK_ENV'] != 'development')
        notify_admins("#{params['role']} finished freemium signup", params.to_s)
      end
    else
      puts "failure, missing some params. params=#{params} and session=#{session.inspect}"
      redirect to '/'
    end

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

  # get '/:class_code/class/?' do
  #   redirect to "/register/#{params[:class_code]}/class"
  # end

  # get '/:class_code/class/?' do
  #   # teacher code, right?
  #   # right now we're searching by teacher_id
    
  #   # get_teacher() <- from st-enroll, i suppose, unless we get the db over here.

  #   # get teacher, then get language

  #   educator = educator?(params[:class_code])
  #   puts "educator = #{educator.inspect}"
  #   if educator
  #     locale = educator[:locale]
  #     type   = educator[:type]
  #     teacher = educator[:educator]
  #     if type == 'school'
  #       halt erb :error
  #     end 
  #   else
  #     halt erb :error
  #   end

  #   # let's just assume it's a teacher for now...........

  #   school = teacher.school

  #   session[:teacher_id] = teacher.id 
  #   session[:teacher_sig] = teacher.signature
  #   session[:school_id] = school.id
  #   session[:school_sig] = school.signature
  #   session[:locale] = locale

  #   # locale stuff.....
  #   text = {}
  #   if locale == 'es'
  #     text[:call_to_action] = "Anótate"
  #     text[:class] = "en la Clase de<br>#{teacher.signature}"
  #     text[:full_name] = "Nombre completo"
  #     text[:full_name_placeholder] = "Nombre y apellido"
  #     text[:phone_number] = "Teléfono"
  #     text[:sign_up] = "Inscribirse"
  #     text[:privacy_policy] = "Al registrarse, acepta nuestras <b>Condiciones de servicio</b> y <b>Política de privacidad</b>"

  #   else # default to english
  #     text[:call_to_action] = "Join"
  #     text[:class] = "#{teacher.signature}'s Class"
  #     text[:full_name] = "Full name"
  #     text[:full_name_placeholder] = "First and last name"
  #     text[:phone_number] = "Phone number"
  #     text[:sign_up] = "Sign up"
  #     text[:privacy_policy] = "By signing up, you agree to our <b>Terms of Service</b> and <b>Privacy Policy</b>"
  #   end

  #   email_admins("Someone from class #{params[:class_code]} accessed web app")
      
  #   erb :register, locals: {text: text, teacher: teacher.signature, school: school.signature}

  # end

  # post '/register/?' do
  #   puts "in post /register"
  #   puts "params = #{params}"
  #   puts "session = #{session.inspect}"
  #   full_name = params['name']
  #   phone_no = params['phone']
  #   mobile_os = params['mobile_os']

  #   if !full_name.nil? && !phone_no.nil? && !mobile_os.nil? && !full_name.empty? && !phone_no.empty? && !mobile_os.empty? # and os != 'unknown'

  #     phone = phone_no.delete(' ').delete('-').delete('(').delete(')')
  #     user = User.where(phone: phone).first

  #     hist = "new"

  #     if !user.nil? # if user exists!!!!!!!
  #       new_user = User.where(phone: phone).first
  #       new_user.update(locale: 'es') if session[:locale] == 'es'
  #       hist = "old"
  #     else
  #       new_user = User.create(phone: phone, platform: mobile_os)
  #       new_user.state_table.update(subscribed?: false)
  #       new_user.update(locale: 'es') if session[:locale] == 'es'
  #       hist = "new"
  #     end

  #     # get session and create associations
  #     teacher = Teacher.where(id: session[:teacher_id]).first
  #     teacher.signup_user(new_user)

  #     # get first and last name
  #     terms = full_name.split(' ')
  #     if terms.size < 1
  #       # return ''
  #       # have a more informative error message?
  #       halt erb :error
  #     elsif terms.size == 1 # just the first name
  #       first_name = terms.first[0].upcase + terms.first[1..-1]
  #       new_user.update(first_name: first_name)
  #     elsif terms.size > 1 # first and last names, baby!!!!!! it's a gold mine over here!!!!
  #       first_name = terms.first[0].upcase + terms.first[1..-1] 
  #       last_name = terms[1..-1].inject("") {|sum, n| sum+" "+(n[0].upcase+n[1..-1])}.strip
  #       new_user.update(first_name: first_name, last_name: last_name)
  #     end

  #     session[:user_id] = new_user.id

  #     # Create a user profile on Mixpanel
  #     tracker.people.set(new_user.id, {
  #         '$first_name'       => new_user.first_name,
  #         '$last_name'        => new_user.last_name,
  #         '$phone'            => new_user.phone,
  #         'platform'    => new_user.platform
  #     });


  #     puts "ABOUT TO NOTIFY ADMINS"
  #     notify_admins("#{hist} user with id #{new_user.id} started registration", params.to_s)

  #   else
  #     halt erb :error
  #   end

  #   redirect to '/register/role'
  # end


  # get '/register/role/?' do
  #   puts "in get /register/role"
  #   # puts "params = #{params}"
  #   puts "session = #{session.inspect}"


  #   text = {}
  #   case session[:locale]
  #   when 'es'
  #     text[:header] = "Cuéntanos algo sobre ti"
  #     text[:identity] = {}
  #     text[:identity][:parent] = ["Soy padre", "Padre, guardián, o familia"]
  #     text[:identity][:teacher] = ["Soy profesor", "Profesor o profesor auxiliar"]
  #     text[:identity][:admin] = ["Soy administrador","Director de escuela o de currículo."]
  #   else
  #     text[:header] = "Tell us about yourself"
  #     text[:identity] = {}
  #     text[:identity][:parent] = ["I'm a parent", "Parent, guardian, or family"]
  #     text[:identity][:teacher] = ["I'm a teacher", "Teacher or assistant teacher"]
  #     text[:identity][:admin] = ["I'm an administrator","School leaders, academic directors"]
  #   end

  #   erb :role, locals: {text: text}
  # end

  # post '/register/role/?' do
  #   puts "in post /register/role"
  #   puts "params = #{params}"
  #   puts "session = #{session.inspect}"
  #   # where do i redirect if there's no session?

  #   user = User.where(id: session[:user_id]).first
  #   if user.nil?
  #     halt erb :error
  #   end
  #   # add validations for the enroll
  #   if ['parent', 'teacher', 'admin'].include? params['role']
  #     user.update(role: params['role'])
  #     # get role, save it in user record 
  #     redirect to '/register/password'
  #   else
  #     halt erb :error
  #   end

  # end


  # get '/register/password/?' do
  #   # puts "params = #{params}"
  #   puts "in get /register/password"
  #   puts "session = #{session.inspect}"


  #   text = {}
  #   case session[:locale]
  #   when 'es'
  #     text[:header] = "Último paso"
  #     text[:subtitle] = "Su contraseña debe contener al menos seis caracteres."
  #     text[:label] = "Crear una contraseña"
  #     text[:placeholder] = "Contraseña"
  #     text[:button] = "Terminar"

  #   else
  #     text[:header] = "Last step"
  #     text[:subtitle] = "Your password must contain at least six characters."
  #     text[:label] = "Choose password"
  #     text[:placeholder] = "Password"
  #     text[:button] = "Save"

  #   end

  #   erb :password, locals: {text: text}
  # end


  # post '/register/password/?' do
  #   puts "in post /register/password"
  #   puts "params = #{params}"
  #   puts "session = #{session.inspect}"

  #   user = User.where(id: session[:user_id]).first
  #   if user.nil?
  #     halt erb :error
  #   end

  #   user.set_password(params['password'])

  #   # get params
  #   # encrypt/store password
  #   # encrypt that shit!
  #   notify_admins("user id=#{session[:user_id]} finished registration", "")

  #   # redirect to  '/register/app'
  #   redirect to  '/coming-soon'

  # end


  # get '/register/app/?' do
  #   # 
  #   puts "in get /register/app"
  #   # puts "params = #{params}"
  #   puts "session = #{session.inspect}"

  #   text = {}
  #   case session[:locale]
  #   when 'es'
  #     text[:header] = "empieza pronto!"
  #     text[:return] = "Vuelve"
  #     text[:weekday] = "el jueves"
  #     text[:date] = "4 de enero!"

  #     text[:header] = "Consigue StoryTime"
  #     text[:subtitle] = "Consigue libros gratis de #{session[:teacher_sig]} directamente en su celular"
  #   else
  #     text[:header] = "starts soon!"
  #     text[:return] = "Come back on"
  #     text[:weekday] = "Thursday"
  #     text[:date] = "January 4th!"

  #     text[:header] = "Get the StoryTime app"
  #     text[:subtitle] = "Get free books from #{session[:teacher_sig]} right on your phone"

  #   end

    

  #   erb :'get-app', locals: {school: session[:school_sig], teacher: session[:teacher_sig], text: text}
  #   # erb :maintenance, locals: {school: session[:school_sig], text: text}
  # end


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

    enroll_families(params)
    erb :internal_success
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
