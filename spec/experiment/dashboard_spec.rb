#  spec/experiment/dashboard_spec.rb       Phil Esterman    
# 
#  Testing the Create Experiment dashboard. 
#  --------------------------------------------------------

# set test enviroment
ENV['RACK_ENV'] = "test"


# DEPENDENCIES 
require_relative "../spec_helper"

require 'capybara/rspec'
require 'rack/test'
require 'timecop'

#for routes to work
require_relative '../../app/app.rb'

require_relative '../../auto-signup'

require_relative "../../experiment/create_experiment"

#testing helpers
require_relative '../../helpers.rb'


describe 'Experiment Dashboard' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe "controller" do 

    it "can access a normal page" do
      get '/'
      expect(last_response.status).to be 200
    end


    context "unauthorized" do 

      it "can't access admin page" do
        get '/admin'
        expect(last_response.status).to be 401
      end

    end


    context "bad authorization" do 
      
      it "doesn't auth" do 
        authorize 'bad', 'boy'
        get '/admin'
        expect(last_response.status).to be 401
      end

    end



    context "good authorization" do 
      
      it "can access page" do 
        authorize 'admin', 'ST'
        get '/admin'
        expect(last_response).to be_ok
      end

    end



  end




end




