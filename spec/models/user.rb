#  spec/models/user.rb 	                      Phil Esterman		
# 
#  A series of tests for the User model. 
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


describe 'User' do
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

   		it "is created by a factory" do 
			user = create(:user)
			expect(user).to_not be nil

   		end

   		it "can access variation" do
   			variation = create(:variation_with_user)
   			user = variation.user
   			expect(user.variations.count).to eq 1
   		end

   		it "can assign variation to user" do
   			user = create(:user)
   			variation = create(:variation)
   # 			user.variations = variation 
   # 			puts user.variations
			# expect(user.variations).to_not be nil
   		end


   		# it "can access experiment through variation" do
   		# 	user = create(:user)
   		# 	variation = create(variation)
   		# 	user.variations.first = variation 

   		# end
end

