#  spec/experiment/dashboard_spec.rb 	                Phil Esterman		
# 
#  A series of tests for A/B experiments and variations. 
#  --------------------------------------------------------

# set test enviroment
ENV['RACK_ENV'] = "test"

# DEPENDENCIES 
require_relative "../spec_helper"

require 'capybara/rspec'
require 'rack/test'
require 'timecop'

require_relative '../../auto-signup'

require_relative "../../experiment/create_experiment"

#testing helpers
require_relative '../../helpers.rb'


describe 'Dashboard' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

    describe "create_experiment" do

    end

end

