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

  # require "sinatra/reloader" if development? 

  # configure :development do
    # register Sinatra::Reloader
  # end

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

    else # default to english
      text[:call_to_action] = "Join"
      text[:class] = "#{teacher.signature}'s Class"
      text[:full_name] = "Full name"
      text[:full_name_placeholder] = "First and last name"
      text[:phone_number] = "Phone number"
      text[:sign_up] = "Sign up"
      text[:privacy_policy] = "By signing up, you agree to our <b>Terms of Service</b> and <b>Privacy Policy</b>"
    end

    email_admins("Someone from class #{params[:class_code]} accessed web app")
      
    erb :register, locals: {text: text,class_code:params[:class_code], locale:locale,teacher_id:teacher.id, teacher: teacher.signature, school: school.signature}

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
        new_user = User.create(phone: phone, platform: mobile_os)
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
      text[:info] = "Le envíaremos un texto pronto con los libros de #{teacher_sig}" 
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
