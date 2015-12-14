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

require_relative '../auto-signup'

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

      it "starts with a nil end_date" do
        create_experiment("time", ["6", "7", "8"], 25, 20)
        expect(Experiment.first.end_date).to be nil
      end


      it "enrolls without experiment" do 
        Signup.enroll(["+15612125831"], 'en', {Carrier: "ATT"})
        @user = User.find_by_phone("+15612125831")
        expect(@user).to_not be nil
      end

      describe "Redis" do 

        before(:each) do
          create_experiment("time", ["6", "7", "8"], 25, 10)
          create_experiment("time", ["6", "7", "8"], 25, 15)
          create_experiment("time", ["6", "7", "8"], 25, 20)
        end

        it "has equal REDIS dates <-> experiments" do
          expect(REDIS.lrange(DAYS_FOR_EXPERIMENT, 0, -1)
                              .count)
                              .to eq 3   
        end

        it "has the first experiment's days rigtmost" do
          expect(REDIS.rpop(DAYS_FOR_EXPERIMENT)).to eq "10" 
        end

      end


    end

    context "enrolling with experiment" do
     
      before(:each) do
        #set current time to Sept, 1 2015, 10:00:00 AM
        Timecop.travel(2015, 9, 1, 10, 0, 0)
        REDIS.del DAYS_FOR_EXPERIMENT 
        @num_users = 25 #original users
        create_experiment("time", ["6", "7", "8"], @num_users, 20)
        Signup.enroll(["+15612125831"], 'en', {Carrier: "ATT"})
        @user = User.find_by_phone("+15612125831")

      end

      it "creates a user" do
        expect(@user).to_not be nil
      end

      it "gives user a variation" do
        expect(@user.variation).to_not be nil
      end

      it "gives user a valid variation" do
        expect(@user.variation.option.class).to be String 
      end

      it "gives a variation a user" do
        user_count = 0 
        #sum all the variation's users
        Experiment.all.first.variations do |var|
          user_count = user_count + var.users.count 
        end
        expect(user_count).to eq 1
      end

      it "gives experiment a user" do 
        expect(Experiment.all.first.users.count).to eq 1
      end

      it "gives user a experiment" do 
        expect(@user.experiment).to_not be nil
      end

      it "pops off the one date from Redis" do 
        expect(REDIS.lrange(DAYS_FOR_EXPERIMENT, 0, -1)
                            .count).to eq 0
      end

      it "pops off the one date from Redis" do 
        expect(REDIS.lrange(DAYS_FOR_EXPERIMENT, 0, -1)
                            .count).to eq 0
      end

      it "sets experiment end_date to DAYS ahead" do
        expect(Experiment.all.first.end_date).to eq 
               Time.new(2015, 9, 16, 10, 0, 0)
      end 

      it "has one less user to assign" do 
        expect(Experiment
                         .all
                         .first
                         .users_to_assign)
                         .to eq (@num_users - 1)
      end












    end






end



