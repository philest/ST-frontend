#  spec/experiment.rb 	                          Phil Esterman		
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

#add experiment & variation models
require_relative '../../models/experiment'
require_relative '../../models/variation'

#testing helpers
require_relative '../../helpers.rb'


describe 'A/B experiments' do
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

    describe 'the Experiment model' do 

   		it 'exists' do 
   			@experiment = Experiment.create()
   			expect(@experiment).to_not be nil 
   		end

   		it 'has a Variation' do
   			@experiment = Experiment.create()
   			@experiment.variations.create(option: "test")
   			expect(@experiment.variations.count).to eq 1 
   			puts "experiment's count of variations: " + \
   					    "#{@experiment.variations.count}"
   		end

   		it 'has many Variations' do
   			@experiment = Experiment.create()
   			@experiment.variations.create(option: "one")
   			@experiment.variations.create(option: "two")
   			@experiment.variations.create(option: "three")
   			expect(@experiment.variations.count).to eq 3 
   			puts "experiment's count of variations: " + \
   					    "#{@experiment.variations.count}"
   		end


   		it "is created by a factory" do 
			experiment = create(:experiment)
			expect(experiment).to_not be nil
   		end

   		it "is created by a factory" do 
			variation = create(:variation_with_experiment)
			expect(variation.experiment).to_not be nil
   		end

      it "accesses users through variations" do
        user_list = create_list(:user, 10) 
        var_list = create_list(:variation, 10)
        exper = create(:experiment)

        #assign each user a variation 
        user_list.zip(var_list).each do |user, var|
          user.variation = var
        end
        #assign every variation to the experiment
        var_list.each do |var|
          exper.variations.push var
        end
        expect(exper.users.count).to eq 10
      end





    end



end



