require 'sinatra/base'

require_relative '../helpers/school_code_helper'
require_relative '../helpers/is_not_us'

# Error tracking. 
# require 'airbrake'
# require_relative '../config/initializers/airbrake'

#analytics
# require 'mixpanel-ruby'

require_relative '../lib/workers'

class Register < Sinatra::Base
  set :root, File.join(File.dirname(__FILE__), '../')

  disable :sessions

  # use Airbrake::Rack::Middleware

  require "sinatra/reloader" if development? 

  configure :development do
    register Sinatra::Reloader
  end

  #set mode (production or test)
  MODE ||= ENV['RACK_ENV']
  PRO ||= "production"
  TEST ||= "test"

  # tracker = Mixpanel::Tracker.new('358fa62873cd7120591bdc455b6098db')

  #########  ROUTES  #########

  helpers SchoolCodeMatcher
  helpers TwilioTextingHelpers
  helpers IsNotUs

  get '/class/?' do
    redirect to '../'
  end


  get '/class/readup' do
    redirect to 'https://invis.io/W3BCF5O2T#/229525683_Details' 
  end


  get '/role/?' do
    puts "in get /register/role"
    # puts "params = #{params}"

    text = {}

      text[:header] = "Cuéntanos algo sobre ti"
      text[:identity] = {}
      text[:identity][:parent] = ["Soy padre", "Padre, guardián, o familia"]
      text[:identity][:teacher] = ["Soy profesor", "Profesor o profesor auxiliar"]
      text[:identity][:admin] = ["Soy administrador","Director de escuela o de currículo."]


    erb :'register/modals/role', locals: {text: text}
  end

  get '/class/:class_code/?' do
    puts "IN REGISTER /CLASS/:CLASS_CODE"

    if params[:class_code].downcase == 'app'
      redirect to '../../app'
      # redirect to 'https://play.google.com/store/apps/details?id=com.mcesterwahl.storytime'
    end

    educator = educator?(params[:class_code])
    puts "educator = #{educator.inspect}"
    if educator
      locale = educator[:locale]
      type   = educator[:type]
      teacher = educator[:educator]
      if type == 'school'
        halt erb :'register/modals/error'
      end 
    else
      halt erb :'register/modals/error'
    end

    # let's just assume it's a teacher for now...........
    school = teacher.school
    puts "school = #{school.inspect}"

    # locale stuff.....
    text = {}
    if locale == 'es'
      text[:call_to_action] = "Anótate"
      text[:class] = "en la Clase de<br>#{teacher.signature}"
      text[:full_name] = "Nombre completo"
      text[:full_name_placeholder] = "Nombre y apellido"
      text[:phone_number] = "Teléfono o correo electrónico"
      text[:sign_up] = "Inscribirse"
      text[:privacy_policy] = "Al registrarse, acepta nuestras <b>Condiciones de servicio</b> y <b>Política de privacidad</b>"

      # role
      text[:header_role] = "Cuéntanos algo sobre ti"
      text[:identity] = {}
      text[:identity][:parent] = ["Soy padre", "Padre, guardián, o familia"]
      text[:identity][:teacher] = ["Soy profesor", "Profesor o profesor auxiliar"]
      text[:identity][:admin] = ["Soy administrador","Director de escuela o de currículo."]

      # password
      text[:header_password] = "Último paso"
      text[:subtitle] = "Su contraseña debe contener al menos seis caracteres."
      text[:label] = "Crear una contraseña"
      text[:placeholder] = "Contraseña"
      text[:button] = "Terminar"

      # coming-soon
      text[:exclaim] = "¡Muy bien!"
      text[:header_maintenance] = "empieza pronto!"
      text[:return] = "Le enviaremos un mensaje de texto"
      text[:weekday] = "el jueves"
      text[:date] = "4 de enero para empezar!"
      text[:info] = "Storytime para iPhobe saldrá <b>la próxima semana</b>! Le enviaremos la app con libros <b>el viernes 10 de febrero.</b>"
      text[:subtitle_maintenance] = "Consigue libros gratis de #{teacher.signature} directamente en su celular"

      text[:header_app] = "Consigue StoryTime"
      text[:subtitle_app] = "Consigue libros gratis de #{teacher.signature} directamente en su celular"

    else # default to english
      text[:call_to_action] = "Join"
      text[:class] = "#{teacher.signature}'s Class"
      text[:full_name] = "Full name"
      text[:full_name_placeholder] = "First and last name"
      text[:phone_number] = "Phone number or email address"
      text[:sign_up] = "Sign up"
      text[:privacy_policy] = "By signing up, you agree to our <b>Terms of Service</b> and <b>Privacy Policy</b>"

      # role
      text[:header_role] = "Tell us about yourself"
      text[:identity] = {}
      text[:identity][:parent] = ["I'm a parent", "Parent, guardian, or family"]
      text[:identity][:teacher] = ["I'm a teacher", "Teacher or assistant teacher"]
      text[:identity][:admin] = ["I'm an administrator","School leaders, academic directors"]

      # password
      text[:header_password] = "Last step"
      text[:subtitle] = "Your password must contain at least six characters."
      text[:label] = "Choose password"
      text[:placeholder] = "Password"
      text[:button] = "Save"

      # coming-soon
      text[:exclaim] = "Great!"
      text[:header_maintenance] = "starts soon!"
      text[:return] = "We will text you on"
      text[:weekday] = "Thursday"
      text[:date] = "January 4th to start!"
      text[:info] = "Storytime for iPhone will be just ONE more week! We will text you the app with books by <b>Friday, February 10.</b>"
      text[:subtitle_maintenance] = "Get free books from #{teacher.signature} right on your phone"

      # get-app
      text[:header_app] = "Get the StoryTime app"
      text[:subtitle_app] = "Get free books from #{teacher.signature} right on your phone"

    end

    email_admins("Someone from class #{params[:class_code]} accessed web app")


    erb :'register/index', locals: {text: text,class_code:params[:class_code], locale:locale,teacher_id:teacher.id, teacher: teacher.signature, school: school.name}

  end


  post '/user-start-registration' do
    puts "new user is starting registration.... #{params}"
    if params.values.include? nil or params.values.include? ""
      # return 400 # or something...
      return [400, { 'Content-Type' => 'text/plain' }, ['Params missing.']]
    end

    full_name     = params['name']
    username      = params['username']
    mobile_os     = params['mobile_os']
    teacher_id    = params['teacher_id']
    locale        = params['locale']
    class_code    = params['class_code']

    test_code = /(\Atest\d+\z)|(\Atest-es\d+\z)/i

    if test_code.match(class_code).nil? and is_not_us?(username) and is_not_us?(full_name)
      notify_admins("user with phone #{username} started registration", params.to_s)
    else
      puts "it's just a test, no reason for concern gentlemen...."
    end

    return 201

  end

  # maybe have an endpoint mid-registration after phone number...........
  post '/user-finish-registration' do

    if params.values.include? nil or params.values.include? ""
      return [400, { 'Content-Type' => 'text/plain' }, ['Params missing.']]
      # return 400 # or something...
    end

    full_name     = params['name']
    username      = params['username']
    mobile_os     = params['mobile_os']
    teacher_id    = params['teacher_id']
    locale        = params['locale']
    
    role          = params['role']
    password      = params['password']
    class_code    = params['class_code']


    # get first and last name
    terms = full_name.split(' ')
    if terms.size < 1
      # return ''
      # have a more informative error message?
      halt erb :'register/modals/error'
    elsif terms.size == 1 # just the first name
      first_name = terms.first[0].upcase + terms.first[1..-1]
      last_name  = ''
    elsif terms.size > 1 # first and last names, baby!!!!!! it's a gold mine over here!!!!
      first_name = terms.first[0].upcase + terms.first[1..-1] 
      last_name = terms[1..-1].inject("") {|sum, n| sum+" "+(n[0].upcase+n[1..-1])}.strip
    end

    params['first_name'] = first_name
    params['last_name']  = last_name

    # username = username.delete(' ').delete('-').delete('(').delete(')')

    # submit this to birdv
    res = HTTParty.post("#{ENV['birdv_url']}/api/auth/signup", body: params)

    puts "res = #{res.inspect}"

    if res.code != 201
      halt erb :'register/modals/error'
    end

    # do something with return if not 201

    puts "ABOUT TO NOTIFY ADMINS"
    test_code = /(\Atest\d+\z)|(\Atest-es\d+\z)/i

    if test_code.match(class_code).nil? and is_not_us?(username) and is_not_us?(password) and is_not_us?(full_name)
      params.delete 'password'
      notify_admins("user with username #{username} finished registration", params.to_s)
    else
      puts "it's just a test, no worries fellas..."
    end

    return 201
  end



  get '/error' do
    halt erb :'register/modals/error' 
  end



end
