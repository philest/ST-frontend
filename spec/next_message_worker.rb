require_relative "./spec_helper"

require 'capybara/rspec'
require 'rack/test'
require 'timecop'

require 'time'
require 'active_support/all'

require_relative '../helpers'
require_relative '../message'
require_relative '../messageSeries'

require_relative '../workers/next_message_worker'
# require_relative '../workers/first_text_worker'

SLEEP_SCALE = 860

SLEEP_TIME = (1/ 8.0)



SPRINT_CARRIER = "Sprint Spectrum, L.P."

START_SMS_1 = "StoryTime: Welcome to StoryTime, free pre-k stories by text! You'll get "

START_SMS_2 = " stories/week-- the first is on the way!\n\nText " + HELP + " for help, or " + STOP + " to cancel."


MMS_ARR = ["http://i.imgur.com/CG1DxZd.jpg", "http://i.imgur.com/GEc0dhT.jpg"]

SMS = "This is a test SMS"

PHONE = "+15612125832"


#clean up leftover jobs
 Sidekiq::Worker.clear_all



describe 'The NextMessageWorker' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end


    before(:each) do
        NextMessageWorker.jobs.clear
        Helpers.initialize_testing_vars
        Timecop.return
        Helpers.testSleep
        User.create(phone: "+15612125832")
    end

    after(:each) do
      Timecop.return
    end


    it "properly adds jobs after calling NextMessageWorker" do
      expect(NextMessageWorker.jobs.size).to eq 0
      NextMessageWorker.perform_in(20.seconds, SMS, MMS_ARR, "+15612125832")
      expect(NextMessageWorker.jobs.size).to eq 1 
      puts "jobs: #{NextMessageWorker.jobs.size}"
    end

    it "has fullSend working even with mms_url in array" do
      @user = User.find_by_phone("+15612125832")
      arr = ["http://image.com"]
      Helpers.fullSend(SMS, arr, @user.phone, "last")

      expect(Helpers.getMMSarr).to eq arr
      expect(Helpers.getSMSarr).to eq [SMS]
    end

    it "properly sends out a single MMS w/ SMS" do
      mms = ["http::image.com"] 
      NextMessageWorker.perform_in(20.seconds, SMS, mms, PHONE)
      expect(NextMessageWorker.jobs.size).to eq 1 
      NextMessageWorker.drain

      expect(Helpers.getMMSarr).to eq mms
      expect(Helpers.getSMSarr).to eq [SMS]
    end

    it "sends out a two SMS stack in the right order" do
      mms_arr = ["one", "two"]
      NextMessageWorker.perform_in(20.seconds, SMS, mms_arr, PHONE)
      puts "jobs: #{NextMessageWorker.jobs.size}"
      NextMessageWorker.drain
      
      # expect(NextMessageWorker.jobs.size).to eq 1
      # expect(Helpers.getMMSarr).to eq ["one"]
      # expect(Helpers.getSMSarr).to eq []

      NextMessageWorker.drain #the recursive call.
      expect(Helpers.getMMSarr).to eq ["one", "two"]
      expect(Helpers.getSMSarr).to eq [SMS]
      expect(NextMessageWorker.jobs.size).to eq 0

    end



      



end
