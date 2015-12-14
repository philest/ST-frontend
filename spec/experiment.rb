#  spec/models/experiment.rb 	                Phil Esterman		
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

require_relative "../experiment/create_experiment"

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

      describe "create_experiment" do

        # clean local Redis storage. 
        before(:each) do
          REDIS.del DAYS_FOR_EXPERIMENT 
        end

        it "makes an experiment" do 
          create_experiment("time", [Time.now], 25, 20)
          expect(Experiment.all.first).to_not be nil
        end 

        it "stores the days in Redis" do 
          create_experiment("time", [Time.now], 25, 20)
          expect(REDIS.lrange(DAYS_FOR_EXPERIMENT, 0, -1).
                  first.to_i).to eq 20
        end 

        it "cleans Redis" do 
          expect(REDIS.lrange(DAYS_FOR_EXPERIMENT, 0, -1)).to be_empty
        end 

        it "has a variable name" do
          create_experiment("time", [Time.now], 25, 20)
          expect(Experiment.all.first.variable).to eq "time"
        end

        it "has a users_to_assign" do
          create_experiment("time", [Time.now], 25, 20)
          expect(Experiment.all.first.users_to_assign).to eq 25
        end

        it "creates the right # of variations" do
          create_experiment("time", ["6", "7", "8"], 25, 20)
          expect(Experiment.first
                           .variations
                           .count)
                           .to eq 3
        end




      end


    end



end



