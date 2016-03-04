require 'sinatra/activerecord' #sinatra w/ DB
require_relative '../config/environments' #DB configuration
require_relative '../models/follower'

#email, to learn of failures
require 'pony'
require_relative '../config/pony'

require 'sinatra/flash'


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
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['admin', 'ST']
  end

  # Create a follower from the HTML form, notify us by email. 
  def create_follower(params)
    Follower.create(name: params[:name],
                  email: params[:email])
  
    if MODE == PRO

      # Report new followers.
      Pony.mail(:to => 'phil.esterman@yale.edu',
            # :cc => 'david.mcpeek@yale.edu',
            :from => 'phil.esterman@yale.edu',
            :subject => "ST: #{params[:name]} subscribed for updates.",
            :body => "Their email is #{params[:email]}. Now, \
                      there's #{Follower.count} people subscribed.")
    end
    flash[:notice] = "Great! We'll keep you updated."

  end

end