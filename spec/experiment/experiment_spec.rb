#  spec/experiment/experiment_spec.rb 	                Phil Esterman		
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
        create_experiment(TIME_FLAG, [[6,40]], 25, 20)
        expect(Experiment.all.first).to_not be nil
      end 

      it "stores the days in Redis" do 
        create_experiment(TIME_FLAG, [[6,40]], 25, 20)
        expect(REDIS.lrange(DAYS_FOR_EXPERIMENT, 0, -1).
                first.to_i).to eq 20
      end 

      it "cleans Redis" do 
        expect(REDIS.lrange(DAYS_FOR_EXPERIMENT, 0, -1)).to be_empty
      end 

      it "has a variable name" do
        create_experiment(TIME_FLAG, [[6,40]], 25, 20)
        expect(Experiment.all.first.variable).to eq TIME_FLAG
      end

      it "has a users_to_assign" do
        create_experiment(TIME_FLAG, [[6,40]], 25, 20)
        expect(Experiment.all.first.users_to_assign).to eq 25
      end

      it "creates the right # of variations" do
        create_experiment(TIME_FLAG, [[6,40],[6,40],[6,40]], 25, 20)
        expect(Experiment.first
                         .variations
                         .count)
                         .to eq 3
      end

      it "starts with a nil end_date" do
        create_experiment(TIME_FLAG, [[6,40],[6,40],[6,40]], 25, 20)
        expect(Experiment.first.end_date).to be nil
      end


      it "enrolls without experiment" do 
        Signup.enroll(["+15612125831"], 'en', {Carrier: "ATT"})
        @user = User.find_by_phone("+15612125831")
        expect(@user).to_not be nil
      end

      describe "Redis" do 

        before(:each) do
          create_experiment(TIME_FLAG, [[6,40],[6,40],[6,40]], 25, 10)
          create_experiment(TIME_FLAG, [[6,40],[6,40],[6,40]], 25, 15)
          create_experiment(TIME_FLAG, [[6,40],[6,40],[6,40]], 25, 20)
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
        Timecop.travel(Time.utc(2015, 9, 1, 10, 0, 0))
        REDIS.del DAYS_FOR_EXPERIMENT 
        @num_users = 25 #original users
        create_experiment(TIME_FLAG, [[6,40],[6,40],[6,40]], @num_users, 15)
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
        Experiment.all.first.variations.to_a.each do |var|
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

      it "if nil, sets experiment end_date to DAYS ahead" do
        expect(Time.at(Experiment.all.first.end_date.to_i)).to eq Time.utc(2015, 9, 16, 10, 0, 0)
      end 

      context "experiment has a date" do 
       
        before(:each) do
          Experiment.all.first.destroy 
          Timecop.travel(Time.utc(2015, 9, 1, 10, 0, 0))
          REDIS.del DAYS_FOR_EXPERIMENT 
          @num_users = 25 #original users
          create_experiment(TIME_FLAG, [[6,40],[6,40],[6,40]], @num_users, 20)
          #set date
          Experiment.all.first.update(end_date: Time.now)
        end

        it "doesn't update date" do
          Timecop.travel(Time.utc(2015, 9, 20, 10, 0, 0))
          Signup.enroll(["+15612125831"], 'en', {Carrier: "ATT"})
          #discount miliseconds 
          expect(Time.at(Experiment.first.end_date.to_i))
                  .to eq Time.at(Time.utc(2015, 9, 1, 10, 0, 0).to_i)
        end

      end

      it "has one less user to assign" do 
        expect(Experiment
                         .all
                         .first
                         .users_to_assign)
                         .to eq (@num_users - 1)
      end

      it "variations only has +/- 1 user difference" do 
        vars = Experiment.all.first.variations
       
        vars.each do |var1|
          vars.each do |var2|
            expect((var1.users.count - var2.users.count).abs).to be <= 1   
          end
        end

      end


      it "raises exception if options_arr is empty" do
        expect{
          create_experiment(DAYS_TO_START_FLAG, [], 10, 20)
        }.to raise_error(ArgumentError)
      end

      it "raises exception if option isn't recognized" do
        expect{
          create_experiment("fake_flag", [1,2], 10, 20)
        }.to raise_error(ArgumentError)
      end



      context "Earlier experiment with no users to assign" do 
        before(:each) do
          Experiment.all.first.destroy 
          @num_users = 20
          create_experiment(TIME_FLAG, [[6,40],[6,40],[6,40]], 0, 20)
          create_experiment(TIME_FLAG, [[6,40],[6,40],[6,40]], 0, 20)
          create_experiment(TIME_FLAG, [[6,40],[6,40],[6,40]], 0, 20)
          REDIS.del DAYS_FOR_EXPERIMENT #simulate using the dates
          create_experiment(DAYS_TO_START_FLAG, [1,2,3], @num_users, 20)
          
          Signup.enroll(["+15612125831"], 'en', {Carrier: "ATT"})
          @user = User.find_by_phone("+15612125831")
        end

          ## Skipping the experiment with zero users_to_assign
        it "enrolls user to first open experiment" do 
          expect(@user.experiment.variable).to eq DAYS_TO_START_FLAG
        end

        it "decrements that experiments users_to_assign" do 
          expect(@user.experiment.users_to_assign).to eq 19
        end

      end 

      context "Earlier experiments just completed signup" do 
        
        before(:each) do
          Experiment.all.first.destroy 
          @num_users = 20
          create_experiment(TIME_FLAG, [[6,40],[6,40],[6,40]], 1, 20)
          create_experiment(DAYS_TO_START_FLAG, [1,2,3], 1, 20)
          create_experiment(TIME_FLAG, [[6,40],[6,40],[6,40]], 1, 20)
          REDIS.del DAYS_FOR_EXPERIMENT #simulate using the dates
          create_experiment(DAYS_TO_START_FLAG, [1,2,3], @num_users, 20)
         
          Signup.enroll(["+15612125831"], 'en', {Carrier: "ATT"})
          @user1 = User.find_by_phone("+15612125831")
          Signup.enroll(["+1"], 'en', {Carrier: "ATT"})
          @user2 = User.find_by_phone("+1")
          Signup.enroll(["+2"], 'en', {Carrier: "ATT"})
          @user3 = User.find_by_phone("+2")
        end

        it "enrolls first user to first" do 
          expect(@user1.experiment.variable).to eq TIME_FLAG
        end

        it "enrolls second user to second" do 
          expect(@user2.experiment.variable).to eq DAYS_TO_START_FLAG
        end

        it "enrolls third user to third" do 
          expect(@user3.experiment.variable).to eq TIME_FLAG
        end

      end

      describe "TIME: date_option" do

        context "NOT daylight savings" do 
          
          before(:each) do
            #delete previous experiments
            Experiment.all.to_a.each do |exper|
              exper.destroy
            end
            #22:30 UTC (17:30 EST --> 5:30 PM on East Coast)
            #-05:00
            Timecop.travel(Time.new(2015, 12, 15, 17, 30, 0))
            create_experiment(TIME_FLAG, [[5,30], [6,30], [6,0], [05,45]], 10, 20)
          end

          it "converts [hour,min] (EST) to option (UTC)" do
            expect(Experiment.first.variations.first.date_option).to eq Time.utc(2015, 12, 15, 22, 30, 0)
          end

          it "has string version" do 
            expect(Experiment.first.variations.first.option).to eq Time.utc(2015, 12, 15, 22, 30, 0).to_s
          end

        end

        context "daylight savings" do 
          
          before(:each) do
            #delete previous experiments
            Experiment.all.to_a.each do |exper|
              exper.destroy
            end
            #22:30 UTC (17:30 EST --> 5:30 PM on East Coast)
            #-05:00
            Timecop.travel(Time.new(2015, 6, 15, 17, 30, 0))
            create_experiment(TIME_FLAG, [[5,30], [6,30], [6,0], [05,45]], 10, 20)
          end

          it "converts [hour,min] (EST) to option (UTC)" do
            expect(Experiment
                            .first
                            .variations
                            .first.date_option)
                            .to eq( 
                            Time.utc(2015, Time.now.month,
                                     Time.now.day, 21, 30, 0)) 
          end

        end


        describe "exceptions" do

          it "raises exception for non-Fixnum times" do
            expect{
              create_experiment(TIME_FLAG, [[5.5,30]], 10, 20)
            }.to raise_error(ArgumentError)
          end

          it "raises exception for too large times (hour)" do
            expect{
              create_experiment(TIME_FLAG, [[15,30]], 10, 20)
            }.to raise_error(ArgumentError)
          end

          it "raises exception for too large times (min)" do
            expect{
              create_experiment(TIME_FLAG, [[6,65]], 10, 20)
            }.to raise_error(ArgumentError)
          end

          it "raises exception for wrong count of option args" do
            expect{
              create_experiment(TIME_FLAG, [[6,30,1]], 10, 20)
            }.to raise_error(ArgumentError)
          end


        end


      end 

      describe "DAYS_TO_START" do

          it "raises exception if days isn't positive" do
            expect{
              create_experiment(DAYS_TO_START_FLAG, [1,2,0], 10, 20)
            }.to raise_error(ArgumentError)
          end

          it "raises exception if days isn't integer" do
            expect{
              create_experiment(DAYS_TO_START_FLAG, [1,2,1.5], 10, 20)
            }.to raise_error(ArgumentError)
          end

          it "saves option as string integer" do
            create_experiment(DAYS_TO_START_FLAG, [1,2], 10, 20)
            expect(Experiment
                            .last
                            .variations
                            .first.option).to eq "1"
          end

      end


    describe "User enrollment" do 

      context "DAYS_TO_START_FLAG" do

        before(:each) do
          Experiment.all.to_a.each do |exper|
            exper.destroy
          end
        
          Signup.enroll(["+1234"], 'en', {Carrier: "ATT"})
          @non_exper_user = User.find_by_phone("+1234")

          create_experiment(DAYS_TO_START_FLAG, [3,4], 10, 20)
          Signup.enroll(["+1561"], 'en', {Carrier: "ATT"})
          @exper_user = User.find_by_phone("+1561")

        end

        it "updates the users relevant attribute" do
          opt = @exper_user.variation.option
          expect(@exper_user.days_per_week).to eq opt.to_i
          puts "user updated to #{opt} days/week"
        end

        it "keeps the users other attributes" do
          exper_attributes = [].push(
            @exper_user.story_number,
            @exper_user.subscribed,
            @exper_user.mms,
            @exper_user.series_choice,
            @exper_user.series_number,
            @exper_user.next_index_in_series,
            @exper_user.awaiting_choice,
            @exper_user.total_messages,
            @exper_user.time,
            @exper_user.locale)

          non_exper_attributes = [].push(
            @non_exper_user.story_number,
            @non_exper_user.subscribed,
            @non_exper_user.mms,
            @non_exper_user.series_choice,
            @non_exper_user.series_number,
            @non_exper_user.next_index_in_series,
            @non_exper_user.awaiting_choice,
            @non_exper_user.total_messages,
            @non_exper_user.time,
            @non_exper_user.locale)
         
          expect(exper_attributes).to eq non_exper_attributes
        end

      end

      context "TIME_FLAG" do

        before(:each) do
          Experiment.all.to_a.each do |exper|
            exper.destroy
          end
        
          Signup.enroll(["+1234"], 'en', {Carrier: "ATT"})
          @non_exper_user = User.find_by_phone("+1234")
          create_experiment(TIME_FLAG, [[6,30], [6,45]], 20, 20)
          Signup.enroll(["+1561"], 'en', {Carrier: "ATT"})
          @exper_user = User.find_by_phone("+1561")
        end

        it "updates the users relevant attribute" do
          @exper_user.reload
          date_opt = @exper_user.variation.date_option
          #HACK to just compare HH:MM because for some
          #strange rspec/activerecord reason updating time
          #doesn't save the day-month change. 
          expect([@exper_user.time.hour].push(@exper_user.time.min)).to eq(
                 [date_opt.hour].push(date_opt.min))
          puts "user updated to #{date_opt} days/week"
        end

        it "keeps the users other attributes" do
          exper_attributes = [].push(
            @exper_user.days_per_week,
            @exper_user.story_number,
            @exper_user.subscribed,
            @exper_user.mms,
            @exper_user.series_choice,
            @exper_user.series_number,
            @exper_user.next_index_in_series,
            @exper_user.awaiting_choice,
            @exper_user.total_messages,
            @exper_user.locale)

          non_exper_attributes = [].push(
            @non_exper_user.days_per_week,
            @non_exper_user.story_number,
            @non_exper_user.subscribed,
            @non_exper_user.mms,
            @non_exper_user.series_choice,
            @non_exper_user.series_number,
            @non_exper_user.next_index_in_series,
            @non_exper_user.awaiting_choice,
            @non_exper_user.total_messages,
            @non_exper_user.locale)
         
          expect(exper_attributes).to eq non_exper_attributes
        end

      end



    end


      #experiment deleted?/sends report after running out of days












    end






end



