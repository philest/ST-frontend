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
                  email: params[:email])
  

      # Report new followers.
      Pony.mail(:to => 'phil.esterman@yale.edu',
            # :cc => 'david.mcpeek@yale.edu',
            :from => 'phil.esterman@yale.edu',
            :subject => "ST: #{params[:email]} subscribed for updates.",
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

    Invite.create(email: params[:email]) 

      # Report new enrollees.
      Pony.mail(:to => 'phil.esterman@yale.edu',
            :cc => 'david.mcpeek@yale.edu',
            :from => 'phil.esterman@yale.edu',
            :subject => "ST: A new person (#{params[:email]}) signed up.",
            :body => "They're on the list to get an invite.")

  end


  def enroll_families(params)

    # Delete all the empty form fields
    params = params.delete_if { |k, v| v.empty? }
    puts params

    # send the families to birdv
    HTTParty.post(ENV['birdv_url'], body: params)

    puts "Posted #{params} to #{ENV['birdv_url']}"


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