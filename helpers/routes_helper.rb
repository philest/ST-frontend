require 'sinatra/activerecord' #sinatra w/ DB
require_relative '../config/environments' #DB configuration
require_relative '../models/follower'
require_relative '../models/invite'

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

  # Check if a user is authorized as admin. 
  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['admin', 'gostorytime']
  end

  # Create a follower from the HTML form, notify us by email. 
  def create_follower(params)
    Follower.create(name: "none",
                  email: params[:email])
  
    if MODE == PRO

      # Report new followers.
      Pony.mail(:to => 'phil.esterman@yale.edu',
            # :cc => 'david.mcpeek@yale.edu',
            :from => 'phil.esterman@yale.edu',
            :subject => "ST: #{params[:email]} subscribed for updates.",
            :body => "Now, \
                      there's #{Follower.count} people subscribed.")
    end
    flash[:notice] = "Great! We'll keep you updated."

  end

  def create_invite

    Invite.create(email: params[:email]) 
    
    if MODE == PRO
      # Report new enrollees.
      Pony.mail(:to => 'phil.esterman@yale.edu',
            :cc => 'david.mcpeek@yale.edu',
            :from => 'phil.esterman@yale.edu',
            :subject => "ST: A new person (#{params[:email]}) signed up.",
            :body => "They're on the list to get an invite.")
    end

  end


  def enroll_families(params)

    # Delete all the empty form fields
    params = params.delete_if { |k, v| v.empty? }
    puts params

    # send the families to birdv
    HTTParty.post(ENV['enroll_url'], body: params)

    puts "Posted #{params} to #{ENV['enroll_url']}"

    if MODE == PRO

      # Report new enrollees.
      Pony.mail(:to => 'phil.esterman@yale.edu',
            :cc => 'david.mcpeek@yale.edu',
            :from => 'phil.esterman@yale.edu',
            :subject => "ST: A new teacher (#{params[:teacher_signature]}) enrolled \
                           #{(params.count / 2)-1} student.",
            :body => "They enrolled: \
                      #{params}.")
    end
    flash[:notice] = "Great! Your class was successfully added."
  end

end