#  app.rb                                     David McPeek      
# 
#  The routes controller. Recieves POST from 
#  www.joinstorytime.com/enroll with family phones and names. 
#  --------------------------------------------------------

#sinatra dependencies 
require 'sinatra/base'
require 'twilio-ruby'
require 'sidekiq'
require 'sidekiq/web'
# require_relative '../config/environment'
require 'pony'
require 'dotenv'
Dotenv.load if ENV['RACK_ENV'] != 'production'
require_relative '../config/pony'
require_relative 'workers' # including twilio_helpers
require_relative '../config/initializers/airbrake'

require_relative 'generate_phone_image'

# aubrey  3013328953
# phil    5612125831
# david   8186897323
# raquel  8188049338
# emily   8184292090

class Enroll < Sinatra::Base
  include TwilioTextingHelpers

  use Airbrake::Rack::Middleware

  enable :sessions
  set :session_secret, ENV['SESSION_SECRET']

  require "sinatra/reloader" if development? 
  configure :development do
    register Sinatra::Reloader
  end

  # before do
  #   headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
  #   headers['Access-Control-Allow-Origin'] = 'http://localhost:4567'
  #   headers['Access-Control-Allow-Headers'] = 'accept, authorization, origin'
  #   headers['Access-Control-Allow-Credentials'] = 'true'
  # end


  get '/user_exists' do
    puts "params=#{params}"
    password_regexp = Regexp.new("^#{params['password']}\\|.+$", 'i')
    school = School.where(Sequel.like(:code, password_regexp)).first

    if school
      teacher = Teacher.where(Sequel.ilike(:email, params['email'])).first
      admin = Admin.where(Sequel.ilike(:email, params['email'])).first

      if teacher and !teacher.signature.nil? and teacher.school.id == school.id
        puts teacher.signature
        return {
          educator: teacher.signature,
          role: 'teacher'
        }.to_json
      end
      
      if admin and !admin.signature.nil? and admin.school.id == school.id
        puts admin.signature
        return {
          educator: admin.signature,
          role: 'admin'
        }.to_json
      end
    end

    puts "false"
    return {educator: 'false', role: 'false'}.to_json

  end

  post '/update_admin' do
    UpdateAdminWorker.perform_async(params[:sig], 
                                      params[:email], 
                                      params[:count], 
                                      params[:teacher_or_teachers], 
                                      params[:list_o_names], 
                                      params[:quicklink])

    email_admins("We just emailed admin #{params[:sig]} with an update", params.to_s)

  end


  post '/update_teacher' do
    UpdateTeacherWorker.perform_async(params[:sig], 
                                      params[:email], 
                                      params[:count], 
                                      params[:family], 
                                      params[:list_o_names], 
                                      params[:quicklink])

    email_admins("We just emailed teacher #{params[:sig]} with an update", params.to_s)

  end


  post '/signup' do

    puts "RACK_ENV = #{ENV['RACK_ENV']}"

    # create teacher here
    email       = params[:email]
    signature   = params[:signature]
    password    = params[:password]
    role        = params[:role]

    puts "st-enroll params = #{params}"

    if email.nil? or signature.nil? or password.nil? or email.empty? or signature.empty? or password.empty? 
      txt = "Email: #{email.inspect}, Signature: #{signature.inspect}, Password: #{password.inspect}"

      missing = []
      missing << "email" if (email.nil? or email.empty?)
      missing << "password" if (password.nil? or password.empty?)
      missing << "signature" if (signature.nil? or signature.empty?)

      notify_admins("A teacher failed to sign in to their account - missing #{missing}", txt)
      return 500
    end

    password_regexp = Regexp.new("^#{password}\\|.+$", 'i')
    
    # note: when we give out passwords, we just do the english version of a school
    school = School.where(Sequel.like(:code, password_regexp)).first
    puts "school = #{school.inspect}"
    puts "this is shit"
    if school.nil?
      return 501
    end

    new_signup = true
    if role == 'admin'
      educator = Admin.where(Sequel.ilike(:email, email)).first
      puts "admin = #{educator.inspect}"
      if educator.nil?
        educator = Admin.create(email: email.downcase)
        new_signup = true
      else
        new_signup = false
      end
    elsif role == 'teacher'
      educator = Teacher.where(Sequel.ilike(:email, email)).first
      puts "teacher = #{educator.inspect}"
      if educator.nil?
        educator = Teacher.create(email: email.downcase)
        new_signup = true
      else
        new_signup = false
      end
    else
      puts "no role given"
      # teacher = Teacher.where(email: email).first
      # admin = Admin.where(email: email).first
      # educator = teacher
      educator = nil
    end

    if educator # bitxh plz
        puts "educator = #{educator.inspect}"
        puts "their school = #{educator.school.inspect}"

        educator.update(signature: signature)
        
        case role
        when 'admin'
          first_name = params[:first_name]
          last_name  = params[:last_name] 

          if first_name and last_name and !first_name.empty? and !last_name.empty?
            educator.update(first_name: params[:first_name], last_name: params[:last_name]) 
          end

          school.add_admin(educator) if new_signup

          if new_signup
            WelcomeAdminWorker.perform_async(educator.id)
          end

        when 'teacher'
          school.signup_teacher(educator)
          educator.reload
          puts "about to do flyerworker thing...."
          FlyerWorker.perform_async(educator.id, school.id) if new_signup
          if new_signup # send notification email
            WelcomeTeacherWorker.perform_async(educator.id)
          end
        end

        educator_hash = educator.to_hash.select {|k, v| [:id, :name, :signature, :email, :code, :t_number, :signin_count].include? k}
        school_hash   = school.to_hash.select {|k, v| [:id, :name, :signature, :code].include? k }

        unless password.downcase == 'test' or password.downcase == 'read'
          if new_signup
            email_admins("#{role.capitalize} #{educator.signature} at #{school.signature} signed up for StoryTime", "Email #{educator.email}")
          else
            email_admins("#{role.capitalize} #{educator.signature} at #{school.signature} signed into their account")
          end
        end

        status 200

        educator.update(signin_count: educator.signin_count + 1)

        return {
          educator: educator_hash,
          school: school_hash,
          secret: 'our little secret',
          role: role
        }.to_json

    end # if educator

  end

  post '/invite_teachers' do

    puts "st-enroll params = #{params}"

    # if admin = Admin.where(id: params['admin_id']).first
    #   admin.update(signin_count: admin.signin_count + 1)
    # end

    NotifyTeacherWorker.perform_async(params)
  end

  get '/teachers/:admin_id' do
    puts "FUCK YOU! #{params[:admin_id]}"

    admin = Admin.where(id: params[:admin_id]).first

    puts "admin is #{admin.inspect}"

    if admin.nil?
      return 404
    end

    teachers_hash = admin.school.teachers.map do |teacher|
      h = teacher.to_hash.select {|k,v| [:id, :signature, :phone, :enrolled_on, :code].include? k }
      h[:books_read] = teacher.users.inject(0) {|sum, user| sum += user.state_table.story_number }
      h[:this_month] = 0
      h[:this_week] = 0
      h[:num_families] = teacher.users.size
      h[:users] = teacher.users.map do |u|
        x = u.to_hash.select {|t,p| [:id, :first_name, :last_name, :phone, :enrolled_on, :locale, :code, :platform, :role].include? t }
        x[:story_number] = u.state_table.story_number
        time_enrolled = (Time.now - u.enrolled_on) / 1.month
        if time_enrolled >= 1
          x[:this_month] = 8 + (u.id % 4)
        else

          time_enrolled_by_week = (Time.now - u.enrolled_on) / 3.weeks
          if time_enrolled_by_week >= 1 # enrolled for
            x[:this_month] = ((8 + (u.id % 4)) * time_enrolled).ceil
          else
            x[:this_month] = 0
          end
          # x[:this_month] = ((8 + (u.id % 4)) * time_enrolled).ceil
        end
        x[:reading_time] = (x[:this_month] * 4.6).ceil
        x[:this_week] = 2 + (u.id % 3)


        if x[:this_month] == 0
          x[:reading_time] = 0
        else 
          x[:reading_time] = (x[:this_month] * 4.6).ceil
        end

        if ['admin', 'teacher'].include? u.role
          x[:this_month] = 0
          x[:reading_time] = 0
        end


        puts "teacher month = #{h[:this_month]}, parent month = #{x[:this_month]}"
        x
      end
      h[:this_month] = h[:users].inject(0) {|sum, user| sum += user[:this_month] }
      h[:reading_time] = h[:users].inject(0) {|sum, user| sum += user[:reading_time] }
      h[:this_week] = h[:users].inject(0) {|sum, user| sum += user[:this_week] }
      h
    end

    # puts "teacher_hash = #{teachers_hash.inspect}"

    return teachers_hash.to_json

  end


  get '/school/users/:admin_id' do
    admin = Admin.where(id: params[:admin_id]).first
    puts "admin is #{admin.inspect}"
    if admin.nil?
      return 404
    end

    users_hash = admin.school.users.map do |u|
      h = u.to_hash.select {|k,v| [:id, :first_name, :last_name, :phone, :enrolled_on, :locale, :code, :platform, :role].include? k }
      h[:story_number] = u.state_table.story_number
      time_enrolled = (Time.now - u.enrolled_on) / 1.month
      if time_enrolled >= 1
        h[:this_month] = 8 + (u.id % 4)
      else
        # h[:this_month] = ((8 + (u.id % 4)) * time_enrolled).ceil

        time_enrolled_by_week = (Time.now - u.enrolled_on) / 3.weeks
        if time_enrolled_by_week >= 1 # enrolled for
          h[:this_month] = ((8 + (u.id % 4)) * time_enrolled).ceil
        else
          h[:this_month] = 0
        end

      end
      h[:this_week] = 2 + (u.id % 3)
      h[:reading_time] = (h[:this_month] * 4.6).ceil

      if h[:this_month] == 0
        h[:reading_time] = 0
      else 
        h[:reading_time] = (h[:this_month] * 4.6).ceil
      end

      if ['admin', 'teacher'].include? u.role
        h[:this_month] = 0
        h[:reading_time] = 0
      end

      puts "month = #{h[:this_month]}, reading_time = #{h[:reading_time]}"

      h
    end

    return users_hash.to_json
    
  end

  get '/users/:teacher_id' do
    teacher = Teacher.where(id: params[:teacher_id]).first

    puts "teacher is #{teacher.inspect}"
    if teacher.nil?
      return 404
    end

    # parents = teacher.users.select {|u| u.role == 'parent' }

    users_hash = teacher.users.map do |u|
      h = u.to_hash.select {|k,v| [:id, :first_name, :last_name, :phone, :enrolled_on, :locale, :code, :platform, :role].include? k }
      h[:story_number] = u.state_table.story_number
      time_enrolled = (Time.now - u.enrolled_on) / 1.month
      if time_enrolled >= 1
        h[:this_month] = 8 + (u.id % 4)
      else
        time_enrolled_by_week = (Time.now - u.enrolled_on) / 3.weeks
        if time_enrolled_by_week >= 1 # enrolled for
          h[:this_month] = ((8 + (u.id % 4)) * time_enrolled).ceil
        else
          h[:this_month] = 0
        end

      end
      h[:this_week] = 2 + (u.id % 3)

      if h[:this_month] == 0
        h[:reading_time] = 0
      else 
        h[:reading_time] = (h[:this_month] * 4.6).ceil
      end

      if ['admin', 'teacher'].include? u.role
        h[:this_month] = 0
        h[:reading_time] = 0
      end

      puts "month = #{h[:this_month]}, reading_time = #{h[:reading_time]}"
      h
    end

    return users_hash.to_json
  end

  get '/admin_sig' do
    puts "admin_sig params = #{params}"
    admin = Admin.where(Sequel.ilike(:email, params['email'])).first
    puts "admin = #{admin.inspect}"
    if admin
      return admin.signature
    end
    return 404
  end

  get '/' do
     'Hello World'
  end

  # DO WE WANT to have a secret key or some other validation so that someone can't overload the system with CURL requests to phone numbers?
  # that's a later challenge.

end

