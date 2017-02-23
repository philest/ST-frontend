#email, to learn of failures
require 'pony'
require_relative '../config/pony'

require 'sinatra/flash'
require 'httparty'
require 'dotenv'
Dotenv.load

# Admin authentication, taken from Sinatra.
module RoutesHelper

  # Mark the route as protected, i.e. requires authentication. 
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  # Create a follower from the HTML form, notify us by email. 
  def create_follower(params)
    Follower.create(name: "none",
                  email: params[:username])
  

      # Report new followers.
      Pony.mail(:to => 'phil.esterman@yale.edu',
            # :cc => 'david.mcpeek@yale.edu',
            :from => 'phil.esterman@yale.edu',
            :subject => "ST: #{params[:username]} subscribed for updates.",
            :body => "Now, \
                      there's #{Follower.count} people subscribed.")
    flash[:notice] = "Great! We'll keep you updated."

  end

  def notify_demo(params)

    flash[:notice] = "Great! Someone from our outreach team will be in touch soon."
    # HTTParty.post(ENV['demo_url'], body: params)
    # puts "\nPosting demo params to #{ENV['demo_url']}\n"
    
      # Report new enrollees.
      Pony.mail(:to => 'phil.esterman@yale.edu',
            :cc => 'david.mcpeek@yale.edu',
            :from => 'phil.esterman@yale.edu',
            :subject => "ST: Demo requested.",
            :body => "Here's all the details so you can follow-up:\n #{params}")

  end

  def create_invite(params)

    Invite.create(email: params[:username]) 

      # Report new enrollees.
      Pony.mail(:to => 'phil.esterman@yale.edu',
            :cc => 'david.mcpeek@yale.edu',
            :from => 'phil.esterman@yale.edu',
            :subject => "ST: A new person (#{params[:username]}) signed up.",
            :body => "They're on the list to get an invite.")

  end


  def enroll_families(params)

    # Delete all the empty form fields
    params = params.delete_if { |k, v| v.empty? }
    puts params

    puts "Posted #{params} to #{ENV['birdv_url']}" 

    # Create the parents
    25.times do |idx| # TODO: this loop is shit
      
      if params["phone_#{idx}"] != nil
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
        end

        # update parent's student name
        if not child_name.nil? then parent.update(:child_name => child_name) end

        # add parent to teacher!
        teacher.add_user(parent)
        puts "added #{parent.child_name if not params["name_#{idx}"].nil?}, phone => #{parent.phone}"

        if !teacher.school.nil? # if this teacher belongs to a school
          teacher.school.add_user(parent)
        end
      
      rescue Sequel::Error => e
        puts e.message
        # TODO: send email to Phil...
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
    flash[:notice] = "Great! Your class was successfully added."
  end

end