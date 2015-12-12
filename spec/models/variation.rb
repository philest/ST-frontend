#  spec/models/variation.rb 	                Phil Esterman		
# 
#  A series of tests for variations. 
#  --------------------------------------------------------

# set test enviroment
ENV['RACK_ENV'] = "test"

# DEPENDENCIES 
require_relative "../spec_helper"

require 'capybara/rspec'
require 'rack/test'
require 'timecop'

#add experiment & variation models
require_relative '../../models/experiment'
require_relative '../../models/variation'

#testing helpers
require_relative '../../helpers.rb'


describe 'the Variation model' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  	#clear background jobs each test. 
    before(:each) do
      Helpers.initialize_testing_vars
      NextMessageWorker.jobs.clear
      NewTextWorker.jobs.clear
      Sidekiq::Worker.clear_all
    end

      it 'exists' do 
        @variation = Variation.create()
        expect(@variation).to_not be nil 
      end

   		it "is created by a factory" do 
			variation = create(:variation_with_experiment)
			expect(variation.experiment).to_not be nil
   		end

   		it "is created by a factory" do 
			variation = create(:variation_with_user)
			expect(variation.user).to_not be nil
   		end



end



