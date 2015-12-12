#  spec/experiment.rb 	                          Phil Esterman		
# 
#  A series of tests for A/B experiments and variations. 
#  --------------------------------------------------------

# set test enviroment
ENV['RACK_ENV'] = "test"

# DEPENDENCIES 
require_relative "./spec_helper"

require 'capybara/rspec'
require 'rack/test'
require 'timecop'

#add experiment & variation models
require_relative '../models/experiment'
require_relative '../models/variation'

#testing helpers
require_relative '../helpers.rb'


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




    end

    describe 'the Variations model' do 

   		it 'exists' do 
   			@variation = Variation.create()
   			expect(@variation).to_not be nil 
   		end

    end






end



