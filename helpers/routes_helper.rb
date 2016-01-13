
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

end