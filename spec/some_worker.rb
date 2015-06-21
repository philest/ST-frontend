require_relative "./spec_helper"

require 'capybara/rspec'
require 'rack/test'
require 'timecop'


require_relative '../helpers'
require_relative '../message'
require_relative '../messageSeries'

SLEEP = (1.0 / 16.0) 


describe 'SomeWorker' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end


    before(:each) do
        SomeWorker.jobs.clear
        Helpers.initialize_testing_vars
        Timecop.return
    end

    after(:each) do
      Timecop.return
    end


    it "properly enques a SomeWorker" do
      expect(SomeWorker.jobs.size).to eq(0)
      SomeWorker.perform_async
      expect(SomeWorker.jobs.size).to eq(1)
    end

    it "starts with no enqued workers" do
      expect(SomeWorker.jobs.size).to eq(0)
    end

    # it "might recurr" do
    #   Timecop.scale(1800) #seconds now seem like hours
    #   puts Time.now

    #   SomeWorker.perform_async
    #   expect(SomeWorker.jobs.size).to eq(1)
    #   SomeWorker.drain
    #   expect(SomeWorker.jobs.size).to eq(0)

    #   sleep 1 
    #   puts Time.now
    # end


    it "recurrs" do

      Timecop.travel(2015, 9, 1, 10, 0, 0) #set Time.now to Sept, 1 2015, 10:00:00 AM at this instant, but allow to move forward


        Timecop.scale(1920) #1/16 seconds now are two minutes
        puts Time.now

        (1..30).each do 

          expect(SomeWorker.jobs.size).to eq(0)

          puts Time.now
          SomeWorker.perform_async

          expect(SomeWorker.jobs.size).to eq(1)

          SomeWorker.drain

          expect(SomeWorker.jobs.size).to eq(0)

          sleep SLEEP
        end

        puts Time.now

    end


    it "asks to update birthdate" do
      User.create(phone: "444", time: "5:30pm", total_messages: 4)

      Timecop.travel(2015, 9, 1, 15, 30, 0) #set Time.now to Sept, 1 2015, 15:30:00  (3:30 PM) at this instant, but allow to move forward

      Timecop.scale(1920) #1/16 seconds now are two minutes

      (1..30).each do 
        SomeWorker.perform_async
        SomeWorker.drain

        sleep SLEEP
      end
      expect(Helpers.getSMSarr).to eq([SomeWorker::BIRTHDATE_UPDATE])
    end








  # it "knows which user gets story next" do
  # 	User.create(name: "Bob", time: "5:30pm", phone: "898")
  # 	User.create(name: "Loria", time: "6:30pm", phone: "798")
  # 	User.create(name: "Jessica", time: "6:30am", phone: "698")

  # 	@user = User.find_by_name("Bob")

  # 	SomeWorker.sendStory?(@user, "12:30pm")
  # end


end