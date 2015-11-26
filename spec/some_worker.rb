require_relative "./spec_helper"

require 'capybara/rspec'
require 'rack/test'
require 'timecop'

require 'sinatra/r18n'
require 'time'
require 'active_support/all'

require_relative '../auto-signup'

require_relative '../helpers'
require_relative '../message'
require_relative '../messageSeries'
require_relative '../workers/first_text_worker'

require_relative '../workers/some_worker'
require_relative '../workers/new_text_worker'

require_relative '../constants'

SLEEP = (1.0 / 16.0) 




SLEEP_SCALE = 860

SLEEP_TIME = (1/ 8.0)




SPRINT_CARRIER = "Sprint Spectrum, L.P."



describe 'SomeWorker' do
  include Rack::Test::Methods
  include Text

  def app
    Sinatra::Application
  end


    before(:each) do
        SomeWorker.jobs.clear
        NextMessageWorker.jobs.clear
        NewTextWorker.jobs.clear
        FirstTextWorker.jobs.clear
        Helpers.initialize_testing_vars
        Timecop.return
        Sidekiq::Testing.inline!
    end

    after(:each) do
      NextMessageWorker.jobs.clear
      Timecop.return
    end


    it "properly enques a SomeWorker" do

      expect(SomeWorker.jobs.size).to eq(0)
      Sidekiq::Testing.fake! do 
        SomeWorker.perform_async
      end
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
      Sidekiq::Testing.fake!

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


    # it "asks to update birthdate" do
    #   User.create(phone: "444", time: "5:30pm", total_messages: 5)

    #   Timecop.travel(2015, 9, 1, 15, 30, 0) #set Time.now to Sept, 1 2015, 15:30:00  (3:30 PM) at this instant, but allow to move forward

    #   Timecop.scale(1920) #1/16 seconds now are two minutes

    #   (1..30).each do 
    #     SomeWorker.perform_async
    #     SomeWorker.drain

    #     sleep SLEEP
    #   end
    #   expect(Helpers.getSMSarr).to eq([SomeWorker::BIRTHDATE_UPDATE])
    # end

    # it "has set_birthdate as true before it sends out the text" do
    #     @user = User.create(phone: "444", time: "5:30pm", total_messages: 5)
      
    #     Timecop.travel(2015, 9, 1, 15, 45, 0) #set Time.now to Sept, 1 2015, 15:45:00  (3:30 PM) at this instant, but allow to move forward

    #     Timecop.scale(1920) #1/16 seconds now are two minutes

    #     (1..20).each do 
    #       SomeWorker.perform_async
    #       SomeWorker.drain

    #       sleep SLEEP
    #     end
    #     @user.reload 

    #     expect(@user.set_birthdate).to be(true)
    # end


    # it "asks to update time when it should (non-sprint" do
    #     @user = User.create(phone: "444", time: TIME_DST, total_messages: 3)

    #     Timecop.travel(2015, 9, 1, 15, 45, 0) #set Time.now to Sept, 1 2015, 15:45:00  (3:30 PM) at this instant, but allow to move forward

    #     Timecop.scale(1920) #1/16 seconds now are two minutes

    #     (1..20).each do 
    #       SomeWorker.perform_async
    #       SomeWorker.drain

    #       sleep SLEEP
    #     end
    #     @user.reload 

    #     expect(Helpers.getSMSarr).to eq([SomeWorker::TIME_SMS_NORMAL])
    # end

    # it "gets all the SPRINT to update time SMS pieces" do
    #     @user = User.create(phone: "444", time: TIME_DST, total_messages: 3, carrier: SPRINT_CARRIER)

    #     Timecop.travel(2015, 9, 1, 15, 45, 0) #set Time.now to Sept, 1 2015, 15:45:00  (3:30 PM) at this instant, but allow to move forward

    #     Timecop.scale(1920) #1/16 seconds now are two minutes

    #     (1..20).each do 
    #       SomeWorker.perform_async
    #       SomeWorker.drain

    #       sleep SLEEP
    #     end
    #     @user.reload 

    #     expect(Helpers.getSMSarr).to eq([SomeWorker::TIME_SMS_SPRINT_1, SomeWorker::TIME_SMS_SPRINT_2])
    # end

    # it "doesn't send time update the next day... (sorry mom)" do
    #     Timecop.travel(2015, 6, 22, 15, 45, 0) #set Time.now to Sept, 1 2015, 15:45:00  (3:30 PM) at this instant, but allow to move forward
    #     @user = User.create(phone: "444", time: TIME_DST, total_messages: 3)

    #     Timecop.travel(2015, 6, 23, 15, 45, 0) #set Time.now to Sept, 1 2015, 15:45:00  (3:30 PM) at this instant, but allow to move forward

    #     Timecop.scale(1920) #1/16 seconds now are two minutes

    #     (1..20).each do 
    #       SomeWorker.perform_async
    #       SomeWorker.drain

    #       sleep SLEEP
    #     end
    #     @user.reload 

    #     expect(Helpers.getSMSarr).to eq([SomeWorker::TIME_SMS_NORMAL])


    #     Timecop.travel(2015, 6, 24, 15, 45, 0)
    #     Timecop.scale(1920) #1/16 seconds now are two minutes

       
    #     (1..20).each do 
    #       SomeWorker.perform_async
    #       SomeWorker.drain

    #       sleep SLEEP
    #     end
    #     @user.reload 

    #     expect(Helpers.getSMSarr).to eq([SomeWorker::TIME_SMS_NORMAL]) #not a second message

    # end

    # it "doesn't send BIRTHDATE update the next day... (sorry mom)" do
    #     @user = User.create(phone: "444", time: TIME_DST, total_messages: 5)

    #     Timecop.travel(2015, 9, 1, 15, 45, 0) #set Time.now to Sept, 1 2015, 15:45:00  (3:30 PM) at this instant, but allow to move forward

    #     Timecop.scale(1920) #1/16 seconds now are two minutes

    #     (1..20).each do 
    #       SomeWorker.perform_async
    #       SomeWorker.drain

    #       sleep SLEEP
    #     end
    #     @user.reload 

    #     expect(Helpers.getSMSarr).to eq([SomeWorker::BIRTHDATE_UPDATE])


    #     Timecop.travel(2015, 9, 2, 15, 45, 0)
       
    #     (1..20).each do 
    #       SomeWorker.perform_async
    #       SomeWorker.drain

    #       sleep SLEEP
    #     end
    #     @user.reload 

    #     expect(Helpers.getSMSarr).to eq([SomeWorker::BIRTHDATE_UPDATE]) #not a second message
    # end


    it "has sendStory? properly working when at time" do
      Timecop.travel(2014, 6, 21, 17, 30, 0) #on prev Sun!
      @user = User.create(phone: "444", time: TIME_DST, days_per_week: 2, total_messages: 4)
      

      Timecop.travel(2015, 6, 23, 17, 30, 0) #on Tuesday!

      time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time)).to be(true)
    end

    it "has sendStory? rightly not working when past time by one minute" do
            Timecop.travel(2014, 6, 21, 17, 30, 0) #on prev Sun!
      @user = User.create(phone: "444", time: TIME_DST, days_per_week: 2, total_messages: 4)
        
      Timecop.travel(2015, 6, 23, 17, 31, 0) #on Tuesday!
      time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time)).to be(false)
    end


    it "has sendStory? rightly NOT working two minutes early" do
         Timecop.travel(2014, 6, 21, 17, 30, 0) #on prev Sun!
      @user = User.create(phone: "444", time: TIME_DST, days_per_week: 2, total_messages: 4)
        
      Timecop.travel(2016, 6, 23, 17, 28, 0) #on Tuesday!

      time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time)).to be(false)
    end


    it "has sendStory? rightly working one min early" do
       Timecop.travel(2014, 6, 21, 17, 30, 0) #on prev Sun!

      @user = User.create(phone: "444", time: TIME_DST, days_per_week: 2, total_messages: 4)
        
      Timecop.travel(2016, 6, 23, 17, 29, 0) #on Tuesday!
      time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time)).to be(true)
    end


    it "properly knows to send at next valid day after 24 hours " do 
      Timecop.travel(2016, 6, 22, 17, 15, 0) #on MONDAY!
      @user = User.create(phone: "444", time: TIME_DST, days_per_week: 2)
      Timecop.travel(2016, 6, 23, 17, 29, 0) #on TUESDAY.
            time = Time.now.utc

      expect(SomeWorker.sendStory?("444", time)).to be(true)
    end

    it "doesn't send within 24 hours of creation " do 
      Timecop.travel(2016, 6, 23, 16, 15, 0) #on TUESDAY!
      @user = User.create(phone: "444", time: TIME_DST, days_per_week: 2)
      Timecop.travel(2016, 6, 23, 17, 29, 0) #on TUESDAY.
            time = Time.now.utc

      expect(SomeWorker.sendStory?("444", time)).to be(false)
    end


    it "sends your first story MMS." do
      Timecop.travel(2016, 6, 22, 17, 15, 0) #on MONDAY!
      @user = User.create(phone: "444", time: TIME_DST, days_per_week: 2)
      Timecop.travel(2016, 6, 23, 17, 24, 0) #on TUESDAY.

      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain

        sleep SLEEP_TIME
      end

      NextMessageWorker.drain

      @user.reload 



      expect(Helpers.getMMSarr).to eq(Message.getMessageArray[0].getMmsArr)
      expect(Helpers.getMMSarr).not_to eq(nil)
    end


   it "sends your first story SMS." do
      Timecop.travel(2016, 6, 22, 17, 15, 0) #on MONDAY!
      @user = User.create(phone: "444", time: TIME_DST, days_per_week: 2)
      Timecop.travel(2016, 6, 23, 17, 24, 0) #on TUESDAY.

      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain

        sleep SLEEP_TIME
      end

      NextMessageWorker.drain

      @user.reload 


      expect(Helpers.getSMSarr).to eq([Message.getMessageArray[0].getSMS])
      expect(Helpers.getSMSarr).not_to eq(nil)
      expect(Helpers.getSMSarr).not_to eq([])
    end


    it "sends only on right days for T-TH schedule (2)" do

      Timecop.travel(2014, 6, 21, 17, 15, 0) #on Sunday!
      @user = User.create(phone: "444", time: TIME_DST, days_per_week: 2)
      
      Timecop.travel(2015, 6, 22, 17, 29, 0) #on Monday.
time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time )).to be(false)

      Timecop.travel(2015, 6, 23, 17, 29, 0) #on T.
time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time )).to be(true)

      Timecop.travel(2015, 6, 24, 17, 29, 0) #on Wed.
time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time )).to be(false)

      Timecop.travel(2015, 6, 25, 17, 29, 0) #on Thurs
time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time )).to be(true)

      Timecop.travel(2015, 6, 26, 17, 29, 0) #on Fri.
time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time )).to be(false)

      Timecop.travel(2015, 6, 27, 17, 29, 0) #on sat.
time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time )).to be(false)

      Timecop.travel(2015, 6, 28, 17, 29, 0) #on sun.
time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time )).to be(false)
  end

  it "sends only on right days for M-W-F schedule (2)" do

      Timecop.travel(2014, 6, 21, 17, 15, 0) #on Sunday!
      @user = User.create(phone: "444", time: TIME_DST, days_per_week: 3)
      
      Timecop.travel(2015, 6, 22, 17, 29, 0) #on Monday.
time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time )).to be(true)

      Timecop.travel(2015, 6, 23, 17, 29, 0) #on T.
time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time )).to be(false)

      Timecop.travel(2015, 6, 24, 17, 29, 0) #on Wed.
time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time )).to be(true)

      Timecop.travel(2015, 6, 25, 17, 29, 0) #on Thurs
time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time )).to be(false)

      Timecop.travel(2015, 6, 26, 17, 29, 0) #on Fri.
time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time )).to be(true)

      Timecop.travel(2015, 6, 27, 17, 29, 0) #on sat.
time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time )).to be(false)

      Timecop.travel(2015, 6, 28, 17, 29, 0) #on Fri.
time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time )).to be(false)
  end


    it "sends only on right days for W schedule (1)" do

      Timecop.travel(2014, 6, 21, 17, 15, 0) #on Sunday!
      @user = User.create(phone: "444", time: TIME_DST, days_per_week: 1)
      
      Timecop.travel(2015, 6, 22, 17, 29, 0) #on Monday.
time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time )).to be(false)

      Timecop.travel(2015, 6, 23, 17, 29, 0) #on T.
time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time )).to be(false)

      Timecop.travel(2015, 6, 24, 17, 29, 0) #on Wed.
time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time )).to be(true)

      Timecop.travel(2015, 6, 25, 17, 29, 0) #on Thurs
time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time )).to be(false)

      Timecop.travel(2015, 6, 26, 17, 29, 0) #on Fri.
time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time )).to be(false)

      Timecop.travel(2015, 6, 27, 17, 29, 0) #on sat.
time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time )).to be(false)

      Timecop.travel(2015, 6, 28, 17, 29, 0) #on Fri.
time = Time.now.utc
      expect(SomeWorker.sendStory?("444", time )).to be(false)
  end



    it "has total message count properly increasing" do
      Sidekiq::Testing.inline!

      Timecop.travel(2015, 6, 22, 17, 15, 0) #on MONDAY!
      # @user = User.create(phone: "444", time: TIME_DST, days_per_week: 2)
      
      Signup.enroll(["444"], 'en', {Carrier: "ATT"})
      @user = User.find_by_phone "444"
      @user.reload

      expect(@user.total_messages).to eq(1)
      expect(@user.story_number).to eq(0)



      Timecop.travel(2015, 6, 23, 17, 20, 0) #on TUESDAY.
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes


      Timecop.travel(2015, 6, 23, 17, 29, 0) #on TUESDAY.
      
      SomeWorker.perform_async
      SomeWorker.drain


      # (1..15).each do 
      #   SomeWorker.perform_async
      #   SomeWorker.drain
      #   sleep SLEEP_TIME
      # end

      NextMessageWorker.drain
      NewTextWorker.drain

      @user.reload 
      expect(@user.total_messages).to eq(2)
      expect(@user.story_number).to eq(1)

      Timecop.travel(2015, 6, 24, 17, 24, 0) #on WED.
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes
      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload 
      expect(@user.total_messages).to eq(2)

      # Timecop.travel(2015, 6, 25, 17, 15, 0) #on Thurs.
      # Timecop.scale(1920) #1/16 seconds now are two minutes
      # (1..20).each do 
      #   SomeWorker.perform_async
      #   SomeWorker.drain
      #   sleep SLEEP
      # end
      # @user.reload 
      # expect(@user.total_messages).to eq(2)


      # Timecop.travel(2015, 6, 26, 17, 15, 0) #on Fri.
      # Timecop.scale(1920) #1/16 seconds now are two minutes     
      # (1..20).each do 
      #   SomeWorker.perform_async
      #   SomeWorker.drain
      #   sleep SLEEP
      # end
      # @user.reload 
      # expect(@user.total_messages).to eq(2)
    end


  #series choice
  it "sends proper texts for first signup through first story and series choice!" do
    Timecop.travel(2015, 6, 22, 16, 15, 0) #on MONDAY!
    get 'test/+15612129000/STORY/ATT'
    @user = User.find_by(phone: "+15612129000")
    @user.reload

    mmsSoFar = Text::FIRST_MMS
    smsSoFar = [ Text::START_SMS_1 + "2" + Text::START_SMS_2]

    NextMessageWorker.drain

    expect(Helpers.getMMSarr).to eq(mmsSoFar)
    expect(Helpers.getSMSarr).to eq(smsSoFar)

    #it properly sends the MMS and SMS on TUES
    Timecop.travel(2015, 6, 23, 17, 24, 0) #on tues!
    Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

    Helpers.testCred

    (1..10).each do 
      SomeWorker.perform_async
      SomeWorker.drain
      sleep SLEEP_TIME
    end
   
    NextMessageWorker.drain

    @user.reload 

    mmsSoFar.concat Message.getMessageArray[0].getMmsArr
    smsSoFar.concat [Message.getMessageArray[0].getSMS]

    expect(Helpers.getMMSarr).to eq(mmsSoFar)
    expect(Helpers.getSMSarr).to eq(smsSoFar)
    expect(Helpers.getMMSarr).not_to eq(nil)

    puts mmsSoFar
    puts smsSoFar
  end



    it "sends the right first weeks (first, then two stories) content" do
        Sidekiq::Testing.fake! 
        Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!
        get 'test/+15612129000/STORY/ATT'
        @user = User.find_by(phone: "+15612129000")
        NextMessageWorker.drain
        @user.reload
        expect(@user.total_messages).to eq(1)


        smsSoFar = [Text::START_SMS_1 + "2" + Text::START_SMS_2]
        expect(Helpers.getSMSarr).to eq(smsSoFar)


        Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes
        (1..10).each do 
          SomeWorker.perform_async
          SomeWorker.drain
          sleep SLEEP_TIME
        end
       
        NextMessageWorker.drain

        @user.reload
        expect(@user.story_number).to eq(0)
        expect(@user.total_messages).to eq(1)



        mmsSoFar = Text::FIRST_MMS
        smsSoFar = [ Text::START_SMS_1 + "2" + Text::START_SMS_2]


        NewTextWorker.drain
        NextMessageWorker.drain


        expect(Helpers.getMMSarr).to eq(mmsSoFar)
        expect(Helpers.getSMSarr).to eq(smsSoFar)


        
        Timecop.travel(2015, 6, 23, 17, 24, 0) #on TUESDAY.
        Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes


        (1..10).each do 
          SomeWorker.perform_async
          SomeWorker.drain
          sleep SLEEP_TIME
        end



        NextMessageWorker.drain
        NewTextWorker.drain


        @user.reload 
        expect(@user.total_messages).to eq(2)
        expect(@user.story_number).to eq(1)

        mmsSoFar.concat Message.getMessageArray[0].getMmsArr
        smsSoFar.concat [Message.getMessageArray[0].getSMS]

        expect(Helpers.getMMSarr).to eq(mmsSoFar)
        expect(Helpers.getSMSarr).to eq(smsSoFar)
        expect(Helpers.getMMSarr).not_to eq(nil)



        Timecop.travel(2015, 6, 24, 17, 24, 0) #on WED. (3:30)
        Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

        (1..10).each do 
          SomeWorker.perform_async
          SomeWorker.drain
          sleep SLEEP_TIME
        end
        @user.reload 
        expect(@user.total_messages).to eq(2)
        expect(@user.story_number).to eq(1)

        #NO CHANGE
        NewTextWorker.drain

        expect(Helpers.getMMSarr).to eq(mmsSoFar)
        expect(Helpers.getSMSarr).to eq(smsSoFar)
        expect(Helpers.getMMSarr).not_to eq(nil)


        Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS. (3:52)
        Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

        (1..10).each do 
          SomeWorker.perform_async
          SomeWorker.drain
          sleep SLEEP_TIME
        end
        @user.reload 

        NewTextWorker.drain

        #They're asked for their story choice during storyTime.
        smsSoFar.push R18n.t.choice.greet[0]
        expect(Helpers.getSMSarr).to eq(smsSoFar)

        @user.reload

        ##registers series text well!
        expect(@user.awaiting_choice).to eq(true)
        expect(@user.next_index_in_series).to eq(0)

        get 'test/+15612129000/d/ATT'
        @user.reload

        NextMessageWorker.drain #OMG forgot this.

        expect(@user.awaiting_choice).to eq(false)
        expect(@user.series_choice).to eq("d")

        messageSeriesHash = MessageSeries.getMessageSeriesHash
        story = messageSeriesHash[@user.series_choice + @user.series_number.to_s][0]

        smsSoFar.push story.getSMS
        mmsSoFar.concat story.getMmsArr

        expect(Helpers.getMMSarr).to eq(mmsSoFar)
        expect(Helpers.getSMSarr).to eq(smsSoFar)

        @user.reload
        #properly update after choice_worker

        expect(@user.next_index_in_series).to eq(nil) #no series
        expect(@user.total_messages).to eq(3)
  end


  it "properly sends out the message about not responding with choice (on next valid day), then drops if don't respond by next" do
      Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!
      @user = User.create(phone: "+15615422025", days_per_week: 2, story_number: 1) #ready to receive story choice

      Timecop.travel(2015, 6, 23, 17, 24, 0) #on TUESDAY.
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload
      
      NewTextWorker.drain

      NextMessageWorker.drain

      smsSoFar = [R18n.t.choice.greet[0]]
      expect(Helpers.getSMSarr).to eq(smsSoFar)

      Timecop.travel(2015, 6, 24, 17, 24, 0) #on WED.
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

    NewTextWorker.drain

      expect(Helpers.getSMSarr).to eq(smsSoFar) #no message

      #EXPECT A DAYLATE MSG when don't respond
      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS.
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

          NewTextWorker.drain


      smsSoFar.push R18n.t.no_reply.day_late + " " + R18n.t.choice.no_greet[0]

      expect(Helpers.getSMSarr).to eq(smsSoFar)
      
      #valid things: 
      expect(@user.next_index_in_series).to eq(999)



      #PROPERLY DROPS THE FOOL w/ no response

      Timecop.travel(2015, 6, 26, 17, 24, 0) #on FRI.
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

    NewTextWorker.drain


      expect(Helpers.getSMSarr).to eq(smsSoFar)


      Timecop.travel(2015, 6, 27, 17, 24, 0) #on SAT.
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

    NewTextWorker.drain


      expect(Helpers.getSMSarr).to eq(smsSoFar)

      Timecop.travel(2015, 6, 30, 17, 24, 0) #on next TUES--> DAY TO DROP!
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

          NewTextWorker.drain



      smsSoFar.push R18n.t.no_reply.dropped
      expect(Helpers.getSMSarr).to eq(smsSoFar)
      expect(@user.subscribed).to eq(false)


      smsSoFar.each do |sms|
        puts sms
      end

    end



    it "properly delivers the next message in a series" do 
      Sidekiq::Testing.fake!
      Timecop.travel(2015, 6, 22, 17, 20, 0) #on MON. (3:52)
      @user = User.create(phone: "+15002125833", story_number: 1, days_per_week: 2)

      Timecop.travel(2015, 6, 23, 17, 24, 0) #on TUES. (3:52)
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload 

      NextMessageWorker.drain
      NewTextWorker.drain

      @user.reload 


      expect(@user.series_number).to eq(0)

      #They're asked for their story choice during storyTime.
      smsSoFar = [R18n.t.choice.greet[0]]
      mmsSoFar = []
      expect(Helpers.getSMSarr).to eq(smsSoFar)

      ##registers series text well!
      expect(@user.awaiting_choice).to eq(true)
      expect(@user.next_index_in_series).to eq(0)

      NewTextWorker.drain


      get 'test/+15002125833/t/ATT'
      @user.reload
      @user.reload

      expect(@user.series_number).to eq(0) #no series

      expect(@user.awaiting_choice).to eq(false)
      expect(@user.series_choice).to eq("t")

      messageSeriesHash = MessageSeries.getMessageSeriesHash
      story = messageSeriesHash[@user.series_choice + @user.series_number.to_s][0]

      NextMessageWorker.drain #OMG forgot this.

      @user.reload
      expect(@user.series_number).to eq(1) #no series


      smsSoFar.push story.getSMS
      mmsSoFar.concat story.getMmsArr

      expect(Helpers.getMMSarr).to eq(mmsSoFar)
      expect(Helpers.getSMSarr).to eq(smsSoFar)

      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS. (3:52)
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_TIME
      end

      NextMessageWorker.drain

      @user.reload 


    #SERIES ENDED, update user
      expect(@user.series_number).to eq(1)
      expect(@user.series_choice).to eq(nil)
      expect(@user.next_index_in_series).to eq(nil)

      # messageSeriesHash = MessageSeries.getMessageSeriesHash
      # story = messageSeriesHash["t" + "0"][1]

      # smsSoFar.push story.getSMS
      # mmsSoFar.concat story.getMmsArr


      #because one pager, hero stories
      mmsSoFar.concat ["http://joinstorytime.org/images/hero1.jpg", 
              "http://joinstorytime.org/images/hero2.jpg"]
      smsSoFar.concat ["StoryTime: Enjoy tonight's superhero story! Whenever you talk or play with your child, you're helping her grow into a super-reader!"]


      expect(Helpers.getMMSarr).to eq(mmsSoFar)
      expect(Helpers.getSMSarr).to eq(smsSoFar)

      puts mmsSoFar
      puts smsSoFar
    end



 it "properly sends SPRINT phones story-choices that are over 160+ in many chunks" do
      Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!
      @user = User.create(phone: "+15615422025", days_per_week: 2, story_number: 1, carrier: SPRINT_CARRIER) #ready to receive story choice

      Timecop.travel(2015, 6, 23, 17, 24, 0) #on TUESDAY.
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

      NewTextWorker.drain

      
      smsSoFar = [R18n.t.choice.greet[0]]
      expect(Helpers.getSMSarr).to eq(smsSoFar)

      Timecop.travel(2015, 6, 24, 17, 24, 0) #on WED.
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

      expect(Helpers.getSMSarr).to eq(smsSoFar) #no message

      #EXPECT A DAYLATE MSG when don't respond
      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS.
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

      smsSoFar.push R18n.t.no_reply.day_late + " " + R18n.t.no_reply.day_late[0]

    NewTextWorker.drain


      expect(Helpers.getSMSarr.last).to_not eq(smsSoFar.last)

      puts Helpers.getSMSarr
  end







 it "properly signs back up after being dropped, then STORY-responding" do
      Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!
      @user = User.create(phone: "+15615422025", days_per_week: 2, story_number: 1) #ready to receive story choice

      Timecop.travel(2015, 6, 23, 17, 24, 0) #on TUESDAY.
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

      NewTextWorker.drain

      smsSoFar = [(R18n.t.choice.greet[0]).to_s]
      expect(Helpers.getSMSarr).to eq(smsSoFar)

      Timecop.travel(2015, 6, 24, 17, 24, 0) #on WED.
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

      expect(Helpers.getSMSarr).to eq(smsSoFar) #no message

      #EXPECT A DAYLATE MSG when don't respond
      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS.
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

      smsSoFar.push R18n.t.no_reply.day_late + " " + R18n.t.choice.no_greet[0]

    NewTextWorker.drain


      expect(Helpers.getSMSarr).to eq(smsSoFar)
      
      #valid things: 
      expect(@user.next_index_in_series).to eq(999)



      #PROPERLY DROPS THE FOOL w/ no response

      Timecop.travel(2015, 6, 26, 17, 24, 0) #on FRI.
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_TIME
      end
    NewTextWorker.drain


      @user.reload
      expect(Helpers.getSMSarr).to eq(smsSoFar)


      Timecop.travel(2015, 6, 27, 17, 24, 0) #on SAT.
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_TIME
      end

          NewTextWorker.drain

      @user.reload
      expect(Helpers.getSMSarr).to eq(smsSoFar)

      Timecop.travel(2015, 6, 30, 17, 24, 0) #on next TUES--> DAY TO DROP!
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

    NewTextWorker.drain


      smsSoFar.push R18n.t.no_reply.dropped.to_str
      expect(Helpers.getSMSarr).to eq(smsSoFar)
      expect(@user.subscribed).to eq(false)


      get 'test/+15615422025/STORY/ATT'
      @user.reload

      expect(@user.awaiting_choice).to be(true)
      expect(@user.subscribed).to be(true)


      #send the SERIES choice

      #welcome back, with series choice
      smsSoFar.push "StoryTime: Welcome back to StoryTime! We'll keep sending you free stories to read aloud." + "\n\n" + R18n.t.choice.no_greet[0].to_s
     

      expect(Helpers.getSMSarr).to eq(smsSoFar)

      smsSoFar.each do |sms|
        puts sms
      end

      #ADD THE RESPONDING WITH STORY, CHECK THAT AWAITINGCHOICE: FALSE, AND SUBSCRIBED TRUE. THEN CHECK ACTUAL
    end


    it "re-offers choice after day-late" do
      Sidekiq::Testing.fake!
      Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!
      @user = User.create(phone: "+15615422025", days_per_week: 2, story_number: 1) #ready to receive story choice

      Timecop.travel(2015, 6, 23, 17, 24, 0) #on TUESDAY.
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload
      
            NewTextWorker.drain

      smsSoFar = [R18n.t.choice.greet[0]]
      expect(Helpers.getSMSarr).to eq(smsSoFar)

      Timecop.travel(2015, 6, 24, 17, 24, 0) #on WED.
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

      expect(Helpers.getSMSarr).to eq(smsSoFar) #no message

      #EXPECT A DAYLATE MSG when don't respond
      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS.
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

          NewTextWorker.drain


      smsSoFar.push R18n.t.no_reply.day_late + " "+ R18n.t.choice.no_greet[0]

      expect(Helpers.getSMSarr).to eq(smsSoFar)
      
      #valid things: 
      expect(@user.next_index_in_series).to eq(999)

       NewTextWorker.drain


      #properly sends out story WHEN they respond
      get 'test/+15615422025/d/ATT'
      @user.reload
      expect(@user.series_choice).to eq("d")

      messageSeriesHash = MessageSeries.getMessageSeriesHash
      story = messageSeriesHash[@user.series_choice + @user.series_number.to_s][0]

      NextMessageWorker.drain #OMG forgot this.
      @user.reload
      expect(@user.series_number).to eq(1) #no series

      expect(@user.awaiting_choice).to eq(false)
      expect(@user.series_choice).to eq(nil)

      messageSeriesHash = MessageSeries.getMessageSeriesHash

      smsSoFar.push story.getSMS
      mmsSoFar = story.getMmsArr

      expect(Helpers.getMMSarr).to eq(mmsSoFar)
      expect(Helpers.getSMSarr).to eq(smsSoFar)


      smsSoFar.each do |sms|
        puts sms
      end
    end

    #TODO
    it "doesn't send story after you just text sample" do
    end

    it "properly assigns the first 10 then 20-300 peeps" do
      
      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS.

      SomeWorker.perform_async
      SomeWorker.drain


      (1..20).each do |num|
       expect(wait = SomeWorker.getWait(SomeWorker::STORY)).to eq(num)
       puts wait
      end

      (21..40).each do |num|

       expect(wait = SomeWorker.getWait(SomeWorker::STORY)).to eq(num + Helpers::MMS_WAIT*2 )
       expect(wait).to eq(num + 40 )
       puts wait

      end

      (41..60).each do |num|
       expect(wait = SomeWorker.getWait(SomeWorker::STORY)).to eq(num + Helpers::MMS_WAIT*4 )
       expect(wait).to eq(num + 80 )
       puts wait
      end


      SomeWorker.perform_async
      SomeWorker.drain

      time_sent = []

      (1..800).each do |num|
       expect(time_sent.include? (wait = SomeWorker.getWait(SomeWorker::STORY))).to be false
        time_sent.push wait

        expect(time_sent.include? wait + Helpers::MMS_WAIT).to be false
        time_sent.push wait + Helpers::MMS_WAIT

        expect(time_sent.include? wait + Helpers::MMS_WAIT*2).to be false
        time_sent.push wait + Helpers::MMS_WAIT*2
      end

      puts time_sent.sort



    end



    it "properly assigns the first 10 then 20-300 peeps" do
      
      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS.

      SomeWorker.perform_async
      SomeWorker.drain


      (1..20).each do |num|
       expect(wait = SomeWorker.getWait(SomeWorker::TEXT)).to eq(num )
       puts wait
      end

      (1..20).each do |num|
       expect(wait = SomeWorker.getWait(SomeWorker::STORY)).to eq(Helpers::MMS_WAIT*2 + num + 20)
       puts wait
      end

      (21..40).each do |num|
        expect(wait = SomeWorker.getWait(SomeWorker::TEXT)).to eq(20 + num + Helpers::MMS_WAIT*4) 
        puts wait
      end

      (21..40).each do |num|
        expect(wait = SomeWorker.getWait(SomeWorker::STORY)).to eq(40 + num + Helpers::MMS_WAIT*6) 
        puts wait
      end


      # (41..60).each do |num|
      #  expect(wait = SomeWorker.getWait(SomeWorker::TEXT)).to eq(num + Helpers::MMS_WAIT*4 )
      #  expect(wait).to eq(num + 80 )
      #  puts wait
      # end


      SomeWorker.perform_async
      SomeWorker.drain

      time_sent = []

      puts '400 trial'

      (1..400).each do |num|

        if num % 2 == 0
          type = SomeWorker::STORY
        else
          type = SomeWorker::TEXT
        end


       expect(time_sent.include? (wait = SomeWorker.getWait(type))).to be false
        time_sent.push wait

        if type == SomeWorker::STORY
          expect(time_sent.include? wait + Helpers::MMS_WAIT).to be false
          time_sent.push wait + Helpers::MMS_WAIT

          expect(time_sent.include? wait + Helpers::MMS_WAIT*2).to be false
          time_sent.push wait + Helpers::MMS_WAIT*2
        end

        puts wait
      end

      puts time_sent.sort

    end

    it "registers locale and sends correct translation" do 

      Sidekiq::Testing.inline!

      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS.
      Signup.enroll(["+15612125833"], 'es', {Carrier: "ATT"})

      @user = User.find_by_phone "+15612125833"
      


      #set up for "no_reply" message
      @user.update(awaiting_choice: false)
      @user.update(story_number: 1)
      @user.update(next_index_in_series: nil)

      Timecop.travel(2016, 6, 23, 17, 30, 0) #First Story Received (THURSDAY!).

      SomeWorker.perform_async


      #set as English
      i18n = R18n::I18n.new('en', ::R18n.default_places)
      R18n.thread_set(i18n)


      expect(Helpers.getSMSarr.last).to_not eq R18n.t.choice.greet[0]
      expect(Helpers.getSMSarr.last).to eq "Hora del Cuento: Hi! Ask your child if they want a story about Tim's cleanup or about a dinosaur party.\n\nReply 't' for Tim or 'd' for dinos."


      ######### Spanish
     
      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS.
      Signup.enroll(["+15612125834"], 'es', {Carrier: "ATT"})

      @user = User.find_by_phone "+15612125834"

              #set up for "greet choice" message
      @user.update(awaiting_choice: false)
      @user.update(story_number: 1)
      @user.update(next_index_in_series: nil)

      Timecop.travel(2016, 6, 23, 17, 30, 0) #First Story Received.
  
      SomeWorker.perform_async


      #set as Spanish
      i18n = R18n::I18n.new('es', ::R18n.default_places)
      R18n.thread_set(i18n)

      expect(Helpers.getSMSarr.last).to eq R18n.t.choice.greet[0]


      #it works for a different locale 
      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS.
      Signup.enroll(["+15612125835"], 'en', {Carrier: "ATT"})

      @user = User.find_by_phone "+15612125835"

              #set up for "greet choice" message
      @user.update(awaiting_choice: false)
      @user.update(story_number: 1)
      @user.update(next_index_in_series: nil)

      Timecop.travel(2016, 6, 23, 17, 30, 0) #First Story Received.
  
      SomeWorker.perform_async

      #set as English
      i18n = R18n::I18n.new('en', ::R18n.default_places)
      R18n.thread_set(i18n)

      expect(Helpers.getSMSarr.last).to eq R18n.t.choice.greet[0]
      expect(Helpers.getSMSarr.last).to eq "StoryTime: Hi! Ask your child if they want a story about Tim's cleanup or about a dinosaur party.\n\nReply 't' for Tim or 'd' for dinos."

    end

    describe "when NON DST" do 

      it "sends at right EST time" do 
      Timecop.travel(2015, 11, 21, 17, 30, 0) #on prev Sun!

      @user = User.create(phone: "444", time: TIME_NO_DST, days_per_week: 2, total_messages: 4)
        
      Timecop.travel(2015, 11, 24, 17, 29, 0) #on Tuesday!
      time = Time.now.utc

      expect(SomeWorker.sendStory?("444", time)).to be(true)

      end 

    end






  # it "knows which user gets story next" do
  # 	User.create(name: "Bob", time: "5:30pm", phone: "898")
  # 	User.create(name: "Loria", time: "6:30pm", phone: "798")
  # 	User.create(name: "Jessica", time: "6:30am", phone: "698")

  # 	@user = User.find_by_name("Bob")

  # 	SomeWorker.sendStory?(@user, "12:30pm")
  # end


end