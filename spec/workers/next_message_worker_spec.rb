require_relative "../spec_helper"

require 'capybara/rspec'
require 'rack/test'
require 'timecop'

require 'time'
require 'active_support/all'

require_relative '../../helpers/twilio_helper'
require_relative '../../stories/story'
require_relative '../../stories/storySeries'

require_relative '../../workers/next_message_worker'

# Last test. 
require_relative '../../app/enroll'

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
        TwilioHelper.initialize_testing_vars
        Timecop.return
        
        User.create(phone: "+15612125832")
        Sidekiq::Testing.inline!
    end

    after(:each) do
      Timecop.return
    end


    it "properly adds jobs after calling NextMessageWorker" do
      Sidekiq::Testing.fake! do 
        expect(NextMessageWorker.jobs.size).to eq 0
        NextMessageWorker.perform_in(20.seconds, SMS, MMS_ARR, "+15612125832")
        expect(NextMessageWorker.jobs.size).to eq 1 
        puts "jobs: #{NextMessageWorker.jobs.size}"
      end
    end

    it "has fullSend working even with mms_url in array" do
      @user = User.find_by_phone("+15612125832")
      arr = ["http://image.com"]
      TwilioHelper.fullSend(SMS, arr, @user.phone, "last")

      expect(TwilioHelper.getMMSarr).to eq arr
      expect(TwilioHelper.getSMSarr).to eq [SMS]
    end

    describe 'perform_in' do 

      it 'properly schedules' do 
        Sidekiq::Testing.fake! do 
          mms = ["http::image.com"] 
          NextMessageWorker.perform_in(20.seconds, SMS, mms, PHONE)
          wait = NextMessageWorker.jobs.first['at'] - NextMessageWorker.jobs.first['created_at']
          expect(wait).to be_within(0.2).of(20)
        end
      end 

    end

    it "properly sends out a single MMS w/ SMS" do
      mms = ["http::image.com"] 
      NextMessageWorker.perform_in(20.seconds, SMS, mms, PHONE)

      expect(TwilioHelper.getMMSarr).to eq mms
      expect(TwilioHelper.getSMSarr).to eq [SMS]
    end

    it "sends out a two MMS stack in the right order" do
      mms_arr = ["one", "two"]
      Sidekiq::Testing.fake! do 
        NextMessageWorker.perform_in(20.seconds, SMS, mms_arr, PHONE)
        puts "jobs: #{NextMessageWorker.jobs.size}"
        NextMessageWorker.drain

        # Can't test iteratively. 
        
      end
      expect(TwilioHelper.getMMSarr).to eq ["one", "two"]
      expect(TwilioHelper.getSMSarr).to eq [SMS]
      expect(NextMessageWorker.jobs.size).to eq 0
    end

    it "sends out a THREE MMS stack in the right order" do
      mms_arr = ["one", "two", 'three']
      Sidekiq::Testing.fake! do 
        NextMessageWorker.perform_in(20.seconds, SMS, mms_arr, PHONE)
        puts "jobs: #{NextMessageWorker.jobs.size}"
        NextMessageWorker.drain
      
      end
      
      expect(TwilioHelper.getMMSarr).to eq ["one", "two", "three"]
      expect(TwilioHelper.getSMSarr).to eq [SMS]
      expect(NextMessageWorker.jobs.size).to eq 0
    end

    it "works for 20 users!" do 
      Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!

      # Build 20 phone numbers.
      numbers = []
      (0..9).each do |num|
        numbers.push "+1561542202"+num.to_s
        numbers.push "+1561542203"+num.to_s
      end

      app_enroll_many(numbers, 'en', {Carrier: 'ATT'})
      @@twiml_sms = []
      @@twiml_mms = []

      expect(User.all.last.total_messages).to eq 1 
      expect(User.all.last.story_number).to eq 0 

      Timecop.travel(2015, 6, 23, 17, 24, 0) #on TUESDAY!
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      #WORKS WIHOUT SLEEPING!
      Sidekiq::Testing.fake! do
        (1..10).each do 
            MainWorker.perform_async
            MainWorker.drain
          sleep SLEEP_TIME
        end

        expect(NextMessageWorker.jobs.size).to eq 20
        NextMessageWorker.drain #send all
      end

      numbers.each do |num|
        user = User.find_by_phone num
        expect(TwilioHelper.getMMSarr.count).to eq(Story.getStoryArray[0].getMmsArr.count * 20)              
        expect(TwilioHelper.getSMSarr.count).to eq([Story.getStoryArray[0].getSMS].count * 20)
        # expect(user.total_messages).to eq()
        expect(user.story_number).to eq(1)
      
      end

    end      



end
