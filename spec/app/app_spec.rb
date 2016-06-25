#  spec/app/app_spec.rb       Phil Esterman    
# 
#  Testing the routes. 
#  --------------------------------------------------------

# set test enviroment
ENV['RACK_ENV'] = "test"

# DEPENDENCIES 
require_relative "../spec_helper"
require 'rack/test'

require_relative '../../app/controllers/app.rb'



describe 'Website' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "loads homepage" do 
      get '/'
      expect(last_response).to be_ok
  end

  it "loads team" do
      get '/team'
      expect(last_response).to be_ok
  end

  it "loads job board" do
      get '/join'
      expect(last_response).to be_ok
  end

  it "loads teacher interface" do
      get '/enroll'
      expect(last_response).to be_ok
  end

  it "loads enroll success page" do
      get '/enroll_success'
      expect(last_response).to be_ok
  end

  it "redirects to the messaging app" do
      get '/books'
      expect(last_response).to have_http_status(:redirect)
  end 

end



