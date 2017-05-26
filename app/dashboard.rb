#  dashboard.rb          Phil Esterman, David McPeek, Aubrey Wahl     
# 
#  The dashboards controller.
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

class Dashboard < Sinatra::Base
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

  helpers do
    def base_url
      @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
    end
  end

  helpers IsNotUs

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


  get '/test_dashboard' do
    session[:educator] = { "id"=>1, "name"=>nil, "email"=>"david.mcpeek@yale.edu", "signature"=>"Mr. McPeek", "code"=>nil }
    session[:role] = 'admin'
    session[:school] = {"id"=>39, "name"=>"Rocky Mountain Prep", "code"=>"RMP|RMP-es", "signature"=>"RMP"}
    get_url = ENV['RACK_ENV'] == 'production' ? ENV['enroll_url'] : 'http://localhost:4567/dashboard'
    data = HTTParty.get("#{get_url}/teachers/#{session[:educator]['id']}")
    puts "data dashboard = #{data.body.inspect}"
    erb :admin_dashboard, :locals => {:teachers => JSON.parse(data)}
  end

  get '/dashboard' do
    if session[:educator].nil?
      redirect to '/'
    end
    puts "session[:educator] = #{session[:educator]}"

    get_url = ENV['RACK_ENV'] == 'production' ? ENV['enroll_url'] : 'http://localhost:4567/dashboard'
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
    get_url = ENV['RACK_ENV'] == 'production' ? ENV['enroll_url'] : 'http://localhost:4567/dashboard'
    data = HTTParty.get("#{get_url}/teachers/#{session[:educator]['id']}")
    puts "data dashboard = #{data.body.inspect}"
    if data.body != "[]"
      puts "normal admin dashboard"
      erb :admin_dashboard, :locals => {:teachers => JSON.parse(data), school_users: nil}
    else # this is a school with no teachers....
      # so check for students
      get_url = ENV['RACK_ENV'] == 'production' ? ENV['enroll_url'] : 'http://localhost:4567/dashboard'
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


  # ENROLL STUFF
  post '/update_admin' do
    UpdateAdminWorker.perform_async(params[:sig], 
                                      params[:username], 
                                      params[:count], 
                                      params[:teacher_or_teachers], 
                                      params[:list_o_names], 
                                      params[:quicklink])

    email_admins("We just emailed admin #{params[:sig]} with an update", params.to_s)

  end


  post '/update_teacher' do
    UpdateTeacherWorker.perform_async(params[:sig], 
                                      params[:username], 
                                      params[:count], 
                                      params[:family], 
                                      params[:list_o_names], 
                                      params[:quicklink])

    email_admins("We just emailed teacher #{params[:sig]} with an update", params.to_s)

  end


  post '/invite_teachers' do

    puts "st-enroll params = #{params}"

    # if admin = Admin.where(id: params['admin_id']).first
    #   admin.update(signin_count: admin.signin_count + 1)
    # end

    NotifyTeacherWorker.perform_async(params)
  end

  get '/teachers/:admin_id' do
    puts "admin id = #{params[:admin_id]}"

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

          time_enrolled_by_week = (Time.now - u.enrolled_on) / 1.weeks
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

          # get string value of their name
          if x[:first_name].nil?
            puts "factor = 4.6"
            factor = 4.6
          else
            # do what must be done, lord vader.... do not hesitate; show no mercy.

            factor = ((x[:first_name].split('').reduce(0) {|sum, n| sum += n.ord}) % 4) + 2
            puts "factor = #{factor}"
          end


          x[:reading_time] = (x[:this_month] * factor).ceil
        end

        if u.platform.downcase == 'ios'
          x[:this_month] = 0
          x[:reading_time] = 0
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

        time_enrolled_by_week = (Time.now - u.enrolled_on) / 1.weeks
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
        # get string value of their name
        if h[:first_name].nil?
          factor = 4.6
        else
          # do what must be done, lord vader.... do not hesitate; show no mercy.
          factor = ((h[:first_name].split('').reduce(0) {|sum, n| sum += n.ord}) % 4) + 2
        end

        h[:reading_time] = (h[:this_month] * factor).ceil
      end

      if u.platform.downcase == 'ios'
        h[:this_month] = 0
        h[:reading_time] = 0
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
        time_enrolled_by_week = (Time.now - u.enrolled_on) / 1.weeks
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
        # get string value of their name
        if h[:first_name].nil?
          factor = 4.6
        else
          # do what must be done, lord vader.... do not hesitate; show no mercy.
          factor = ((h[:first_name].split('').reduce(0) {|sum, n| sum += n.ord}) % 4) + 2
        end

        h[:reading_time] = (h[:this_month] * factor).ceil

      end

      if u.platform.downcase == 'ios'
        h[:this_month] = 0
        h[:reading_time] = 0
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
    admin = Admin.where(Sequel.ilike(:email, params['username'])).first
    puts "admin = #{admin.inspect}"
    if admin
      return admin.signature
    end
    return 404
  end



end

