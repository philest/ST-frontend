require_relative "./spec_helper"

require 'capybara/rspec'
require 'rack/test'
require 'timecop'

require 'time'
require 'active_support/all'

require_relative '../helpers'
require_relative '../message'
require_relative '../messageSeries'
require_relative '../workers/first_text_worker'
require_relative '../workers/next_message_worker'

require_relative '../constants'

SLEEP_SCALE = 860

SLEEP_TIME = (1/ 8.0)



SPRINT_CARRIER = "Sprint Spectrum, L.P."


describe 'SomeWorker, with sleep,' do
  include Rack::Test::Methods
  include Text

  def app
    Sinatra::Application
  end


    before(:each) do
        NextMessageWorker.jobs.clear
        SomeWorker.jobs.clear
        Helpers.initialize_testing_vars
        Timecop.return
        Helpers.testSleep
    end

    after(:each) do
      Timecop.return
    end


    it "properly sends out messages to 10 users (no sleep.)" do
      Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!
      users = []

      Helpers.testSleepOff

      (1..10).each do |number|
        get 'test/'+number.to_s+"/STORY/ATT"#each signs up
        user = User.find_by(phone: number)

        NextMessageWorker.drain
        user.reload

        expect(user.total_messages).to eq(1)
        expect(user.story_number).to eq(0)

        expect(Helpers.getSMSarr).to eq([Text::START_SMS_1 + "2" + Text::START_SMS_2,
                                        Text::FIRST_SMS])              
        expect(Helpers.getMMSarr).to eq(Text::FIRST_MMS)

        users.push user

        @@twiml_sms = []
        @@twiml_mms = []
      end

      Timecop.travel(2015, 6, 23, 17, 26, 0) #on TUESDAY!
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      # Helpers.testSleep
      # require 'pry'
      # binding.pry 

      #WORKS WIHOUT SLEEPING!
      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_TIME
      end 

      NextMessageWorker.drain

      users.each do |user|
        user.reload
        expect(user.total_messages).to eq(2)
        expect(user.story_number).to eq(1)
        puts " "+ user.phone + "passed"
      end

    end


  it "properly sends out messages to 10 users (sleep!)" do
      Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!
      users = []

      Helpers.testSleepOff

      (1..10).each do |number|
        get 'test/'+number.to_s+"/STORY/ATT"#each signs up
        user = User.find_by(phone: number)

        NextMessageWorker.drain
        user.reload

        expect(user.total_messages).to eq(1)
        expect(user.story_number).to eq(0)

        expect(Helpers.getSMSarr).to eq([Text::START_SMS_1 + "2" + Text::START_SMS_2,
                                        Text::FIRST_SMS])              
        expect(Helpers.getMMSarr).to eq(Text::FIRST_MMS)

        expect(user.total_messages).to eq 1

        users.push user

        @@twiml_sms = []
        @@twiml_mms = []
      end


      Helpers.testSleep
      # require 'pry'
      # binding.pry 

      Timecop.travel(2015, 6, 23, 17, 30, 0) #on TUESDAY!
      # Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

        SomeWorker.perform_async
        SomeWorker.drain

        NextMessageWorker.drain

      users.each do |user|
        user.reload
        expect(user.total_messages).to eq(2)
        expect(user.story_number).to eq(1)
        puts " "+ user.phone + "passed"
      end

    end



    it "handles a single mms" do
      Helpers.new_just_mms("http://i.imgur.com/Qkh15vl.png?1", "+15612125833")
      expect(Helpers.getMMSarr[0]).to eq "http://i.imgur.com/Qkh15vl.png?1"
      expect(Helpers.getSMSarr.empty?).to be true
    end


    # it "blocks properly: sending the second message to the 1st person BEFORE the 1st message to 21st person." do
    #         Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!
    #   users = []

    #   Helpers.testSleepOff

    #   (1..25).each do |number|
    #     get 'test/'+number.to_s+"/STORY/ATT"#each signs up
    #     user = User.find_by(phone: number)

    #     NextMessageWorker.drain
    #     user.reload

    #     expect(user.total_messages).to eq(1)
    #     expect(user.story_number).to eq(0)

    #     expect(Helpers.getSMSarr).to eq([Text::START_SMS_1 + "2" + Text::START_SMS_2,
    #                                     FirstTextWorker::FIRST_SMS])              
    #     expect(Helpers.getMMSarr).to eq(FIRST_MMS)

    #     expect(user.total_messages).to eq 1

    #     users.push user

    #     @@twiml_sms = []
    #     @@twiml_mms = []
    #   end


    #   Helpers.testSleep
    #   # require 'pry'
    #   # binding.pry 

    #   Timecop.travel(2015, 6, 23, 17, 30, 0) #on TUESDAY!
    #   # Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

    #     SomeWorker.perform_async
    #     SomeWorker.drain

    #     NextMessageWorker.drain

    #   users.each do |user|
    #     user.reload
    #     expect(user.total_messages).to eq(2)
    #     expect(user.story_number).to eq(1)
    #     puts " "+ user.phone + "passed"
    #   end
    # end

    



end