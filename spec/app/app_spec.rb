#  spec/app/app_spec.rb       Phil Esterman    
# 
#  Testing the routes. 
#  --------------------------------------------------------

# set test enviroment
ENV['RACK_ENV'] = "test"

# DEPENDENCIES 
require_relative "../spec_helper"
require 'rack/test'

require_relative '../../app/app.rb'



describe 'Website',  :type => :request do
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
      get '/signup'
      expect(last_response).to be_ok
  end

  it "loads enroll success page" do
      post '/enroll_families_form_success' 
      expect(last_response).to be_ok
  end

  it "redirects" do
      get '/books'
      expect(last_response).to be_redirect   # This works, but I want it to be more specific
  end 

  it "redirects to the messaging app" do
      get '/books'
      follow_redirect!
      expect(last_request.url).to eq 'http://m.me/490917624435792'
  end 






end



