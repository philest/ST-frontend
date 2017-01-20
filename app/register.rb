require 'sinatra/base'

require_relative '../helpers/school_code_helper'

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

  get '/class/?' do
    redirect to '/'
  end

  get '/class/:class_code/?' do
    puts "IN REGISTER /CLASS/:CLASS_CODE"

    if params[:class_code].downcase == 'app'
      redirect to 'https://play.google.com/store/apps/details?id=com.mcesterwahl.storytime'
    end

    educator = educator?(params[:class_code])
    puts "educator = #{educator.inspect}"
    if educator
      locale = educator[:locale]
      type   = educator[:type]
      teacher = educator[:educator]
      if type == 'school'
        halt erb :error
      end 
    else
      halt erb :error
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
      text[:phone_number] = "Teléfono"
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
      text[:info] = "Storytime para iPhobe saldrá <b>la próxima semana</b>! Le enviaremos la app con libros <b>el próximo viernes.</b>"
      text[:subtitle_maintenance] = "Consigue libros gratis de #{teacher.signature} directamente en su celular"

      text[:header_app] = "Consigue StoryTime"
      text[:subtitle_app] = "Consigue libros gratis de #{teacher.signature} directamente en su celular"

    else # default to english
      text[:call_to_action] = "Join"
      text[:class] = "#{teacher.signature}'s Class"
      text[:full_name] = "Full name"
      text[:full_name_placeholder] = "First and last name"
      text[:phone_number] = "Phone number"
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
      text[:info] = "Storytime for iPhone comes out in <b>one week</b>! We will text you the app with books <b>next Friday</b>"
      text[:subtitle_maintenance] = "Get free books from #{teacher.signature} right on your phone"

      # get-app
      text[:header_app] = "Get the StoryTime app"
      text[:subtitle_app] = "Get free books from #{teacher.signature} right on your phone"

    end

    email_admins("Someone from class #{params[:class_code]} accessed web app")


    erb :register, locals: {text: text,class_code:params[:class_code], locale:locale,teacher_id:teacher.id, teacher: teacher.signature, school: school.signature}

  end




  # get 'get-app' do





  # end


  get '/role/?' do
    puts "in get /register/role"
    # puts "params = #{params}"

    text = {}

      text[:header] = "Cuéntanos algo sobre ti"
      text[:identity] = {}
      text[:identity][:parent] = ["Soy padre", "Padre, guardián, o familia"]
      text[:identity][:teacher] = ["Soy profesor", "Profesor o profesor auxiliar"]
      text[:identity][:admin] = ["Soy administrador","Director de escuela o de currículo."]


    erb :'role', locals: {text: text}
  end

  post '/user-start-registration' do
    puts "new user is starting registration.... #{params}"
    if params.values.include? nil or params.values.include? ""
      # return 400 # or something...
      return [400, { 'Content-Type' => 'text/plain' }, ['Params missing.']]
    end

    full_name     = params['name']
    phone_no      = params['phone']
    mobile_os     = params['mobile_os']
    teacher_id    = params['teacher_id']
    locale        = params['locale']
    class_code    = params['class_code']

    phone = phone_no.delete(' ').delete('-').delete('(').delete(')')

    user = User.where(phone: phone).first

    hist = "new"
    if !user.nil? # if user exists!!!!!!!
      user = User.where(phone: phone).first
      user.update(platform: mobile_os.downcase)
      user.update(locale: 'es') if locale == 'es'
      hist = "old"
    else
      user = User.create(phone: phone, platform: mobile_os.downcase)
      user.state_table.update(subscribed?: false)
      user.update(locale: 'es') if locale == 'es'
      hist = "new"
    end

    teacher = Teacher.where(id: teacher_id).first
    teacher.signup_user(user) if teacher

    # get first and last name
    terms = full_name.split(' ')
    if terms.size < 1
      # return ''
      # have a more informative error message?
      halt erb :error
    elsif terms.size == 1 # just the first name
      first_name = terms.first[0].upcase + terms.first[1..-1]
      user.update(first_name: first_name)
    elsif terms.size > 1 # first and last names, baby!!!!!! it's a gold mine over here!!!!
      first_name = terms.first[0].upcase + terms.first[1..-1] 
      last_name = terms[1..-1].inject("") {|sum, n| sum+" "+(n[0].upcase+n[1..-1])}.strip
      user.update(first_name: first_name, last_name: last_name)
    end

    puts "ABOUT TO NOTIFY ADMINS"

    puts "user = #{user.inspect}"
    puts "teacher = #{user.teacher.inspect}"

    test_code = /(\Atest\d+\z)|(\Atest-es\d+\z)/i

    if test_code.match(class_code).nil?
      notify_admins("#{hist} user with id #{user.id} started registration", params.to_s)
    else
      puts "it's just a test, no reason for concern gentlemen...."
    end

    return 201

  end

  # maybe have an endpoint mid-registration after phone number...........
  post '/user-finish-registration' do
    # do stuff.... 
    puts "creating user.... #{params}"

    if params.values.include? nil or params.values.include? ""
      return [400, { 'Content-Type' => 'text/plain' }, ['Params missing.']]
      # return 400 # or something...
    end

    full_name     = params['name']
    phone_no      = params['phone']
    mobile_os     = params['mobile_os']
    teacher_id    = params['teacher_id']
    locale        = params['locale']
    
    role          = params['role']
    password      = params['password']
    class_code    = params['class_code']

    phone = phone_no.delete(' ').delete('-').delete('(').delete(')')

    user = User.where(phone: phone).first

    if !user.nil? # if user exists!!!!!!!
      user = User.where(phone: phone).first
      user.update(platform: mobile_os.downcase)
      user.update(locale: 'es') if locale == 'es'
    else
      user = User.create(phone: phone, platform: mobile_os.downcase)
      user.state_table.update(subscribed?: false)
      user.update(locale: 'es') if locale == 'es'
    end

    teacher = Teacher.where(id: teacher_id).first
    teacher.signup_user(user) if teacher

    # set password
    user.set_password(password)

    # update the rest
    user.update(role: role, class_code: class_code)

    # get first and last name
    terms = full_name.split(' ')
    if terms.size < 1
      # return ''
      # have a more informative error message?
      halt erb :error
    elsif terms.size == 1 # just the first name
      first_name = terms.first[0].upcase + terms.first[1..-1]
      user.update(first_name: first_name)
    elsif terms.size > 1 # first and last names, baby!!!!!! it's a gold mine over here!!!!
      first_name = terms.first[0].upcase + terms.first[1..-1] 
      last_name = terms[1..-1].inject("") {|sum, n| sum+" "+(n[0].upcase+n[1..-1])}.strip
      user.update(first_name: first_name, last_name: last_name)
    end

    # Create a user profile on Mixpanel
    # tracker.people.set(user.id, {
    #     '$first_name'       => user.first_name,
    #     '$last_name'        => user.last_name,
    #     '$phone'            => user.phone,
    #     'platform'          => user.platform
    # });


    puts "ABOUT TO NOTIFY ADMINS"
    params['password'] = user.password_digest

    test_code = /(\Atest\d+\z)|(\Atest-es\d+\z)/i

    if test_code.match(class_code).nil?
      notify_admins("user with id #{user.id} finished registration", params.to_s)
    else
      puts "it's just a test, no worries fellas..."
    end

    puts "user = #{user.inspect}"
    puts "teacher = #{user.teacher.inspect}"

    return 201
    # redirect to '/get-app'
  end

  get '/coming-soon' do
    puts "params = #{params}"

    text = {}
    case params[:locale]
    when 'es'
      text[:exclaim] = "¡Muy bien!"
      text[:header] = "empieza pronto!"
      text[:return] = "Le enviaremos un mensaje de texto"
      text[:weekday] = "el jueves"
      text[:date] = "4 de enero para empezar!"
      text[:info] = "Storytime para iPhobe saldrá <b>la próxima semana</b>! Le enviaremos la app con libros <b>el próximo viernes.</b>"

      text[:subtitle] = "Consigue libros gratis de #{params[:teacher_sig]} directamente en su celular"
    else
      text[:exclaim] = "Great!"
      text[:header] = "starts soon!"
      text[:return] = "We will text you on"
      text[:weekday] = "Thursday"
      text[:date] = "January 4th to start!"
      text[:info] = "Storytime for iPhone comes out in one week! We will text you the app with books next Friday"


      text[:subtitle] = "Get free books from #{params[:teacher_sig]} right on your phone"

    end

    # erb :'get-app', locals: {school: session[:school_sig], teacher: session[:teacher_sig], text: text}
    # erb :maintenance, locals: {school: session[:school_sig], text: text}

    erb :maintenance, locals: {school: params[:school_sig], teacher: params[:teacher_sig], text: text}
  end


  post '/' do
    puts "IN POST / FOR REGISTER"

    puts "params = #{params}"


    full_name = params['name']
    phone_no = params['phone']
    mobile_os = params['mobile_os']
    teacher_id = params['teacher_id']
    locale = params['locale']


    if !full_name.nil? && !phone_no.nil? && !mobile_os.nil? && !full_name.empty? && !phone_no.empty? && !mobile_os.empty? # and os != 'unknown'

      phone = phone_no.delete(' ').delete('-').delete('(').delete(')')
      user = User.where(phone: phone).first

      hist = "new"

      if !user.nil? # if user exists!!!!!!!
        new_user = User.where(phone: phone).first
        new_user.update(locale: 'es') if locale == 'es'
        hist = "old"
      else
        new_user = User.create(phone: phone, platform: mobile_os.downcase)
        new_user.state_table.update(subscribed?: false)
        new_user.update(locale: 'es') if locale == 'es'
        hist = "new"
      end

      teacher = Teacher.where(id: teacher_id).first
      teacher.signup_user(new_user)

      # get first and last name
      terms = full_name.split(' ')
      if terms.size < 1
        # return ''
        # have a more informative error message?
        halt erb :error
      elsif terms.size == 1 # just the first name
        first_name = terms.first[0].upcase + terms.first[1..-1]
        new_user.update(first_name: first_name)
      elsif terms.size > 1 # first and last names, baby!!!!!! it's a gold mine over here!!!!
        first_name = terms.first[0].upcase + terms.first[1..-1] 
        last_name = terms[1..-1].inject("") {|sum, n| sum+" "+(n[0].upcase+n[1..-1])}.strip
        new_user.update(first_name: first_name, last_name: last_name)
      end

      # Create a user profile on Mixpanel
      # tracker.people.set(new_user.id, {
      #     '$first_name'       => new_user.first_name,
      #     '$last_name'        => new_user.last_name,
      #     '$phone'            => new_user.phone,
      #     'platform'          => new_user.platform
      # });


      puts "ABOUT TO NOTIFY ADMINS"
      notify_admins("#{hist} user with id #{new_user.id} started registration", params.to_s)

    else
      halt erb :error
    end

    redirect to "/coming-soon?teacher=#{teacher.signature}&locale=#{locale}"
  end

  get '/error' do
    halt erb :error 
  end


  # get '/:code/class' do
  #   erb :maintenance
  # end
  get '/coming-soon' do
    puts "IN /COMING-SOON FOR REGISTER"
    puts "params = #{params}"
    teacher_sig = params['teacher']
    locale = params['locale']

    text = {}
    case locale
    when 'es'
      text[:exclaim] = "¡Muy bien!"
      text[:header] = "empieza pronto!"
      text[:return] = "Le enviaremos un mensaje de texto"
      text[:weekday] = "el jueves"
      text[:date] = "4 de enero para empezar!"
      text[:info] = "Storytime para iPhobe saldrá <b>la próxima semana</b>! Le enviaremos la app con libros <b>el próximo viernes.</b>"
      text[:subtitle] = "Consigue libros gratis de #{teacher_sig} directamente en su celular"
    else
      text[:exclaim] = "Great!"
      text[:header] = "starts soon!"
      text[:return] = "We will text you on"
      text[:weekday] = "Thursday"
      text[:date] = "January 4th to start!"
      text[:info] = "We'll text you in a few days with #{teacher_sig}'s books!"
      text[:subtitle] = "Get free books from #{teacher_sig} right on your phone"

    end

    erb :maintenance, locals: {teacher: teacher_sig, text: text}
  end

end
