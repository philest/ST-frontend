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

SLEEP = (1.0 / 16.0) 


SLEEP_960 =  (1/ 8.0)


SPRINT_CARRIER = "Sprint Spectrum, L.P."



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
    #     @user = User.create(phone: "444", time: SomeWorker::DEFAULT_TIME, total_messages: 3)

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
    #     @user = User.create(phone: "444", time: SomeWorker::DEFAULT_TIME, total_messages: 3, carrier: SPRINT_CARRIER)

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
    #     @user = User.create(phone: "444", time: SomeWorker::DEFAULT_TIME, total_messages: 3)

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
    #     @user = User.create(phone: "444", time: SomeWorker::DEFAULT_TIME, total_messages: 5)

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
      Timecop.travel(2014, 6, 23, 17, 30, 0) #on Tuesday!
      @user = User.create(phone: "444", time: SomeWorker::DEFAULT_TIME, days_per_week: 2, total_messages: 4)
        
      Timecop.travel(2015, 6, 23, 17, 30, 0) #on Tuesday!
      expect(SomeWorker.sendStory?("444")).to be(true)
    end

    it "has sendStory? rightly not working when past time by one minute" do
      @user = User.create(phone: "444", time: SomeWorker::DEFAULT_TIME, days_per_week: 2, total_messages: 4)
        
      Timecop.travel(2015, 6, 23, 17, 31, 0) #on Tuesday!

      expect(SomeWorker.sendStory?("444")).to be(false)
    end


    it "has sendStory? rightly NOT working two minutes early" do
      @user = User.create(phone: "444", time: SomeWorker::DEFAULT_TIME, days_per_week: 2, total_messages: 4)
        
      Timecop.travel(2016, 6, 23, 17, 28, 0) #on Tuesday!
      expect(SomeWorker.sendStory?("444")).to be(false)
    end


    it "has sendStory? rightly working one min early" do
      @user = User.create(phone: "444", time: SomeWorker::DEFAULT_TIME, days_per_week: 2, total_messages: 4)
        
      Timecop.travel(2016, 6, 23, 17, 29, 0) #on Tuesday!

      expect(SomeWorker.sendStory?("444")).to be(true)
    end


    it "properly knows to send at next valid day after 24 hours " do 

      Timecop.travel(2016, 6, 22, 17, 15, 0) #on MONDAY!
      @user = User.create(phone: "444", time: SomeWorker::DEFAULT_TIME, days_per_week: 2)
      Timecop.travel(2016, 6, 23, 17, 29, 0) #on TUESDAY.
      expect(SomeWorker.sendStory?("444")).to be(true)
    end

    it "doesn't send within 24 hours of creation " do 
      Timecop.travel(2016, 6, 23, 16, 15, 0) #on TUESDAY!
      @user = User.create(phone: "444", time: SomeWorker::DEFAULT_TIME, days_per_week: 2)
      Timecop.travel(2016, 6, 23, 17, 29, 0) #on TUESDAY.
      expect(SomeWorker.sendStory?("444")).to be(false)
    end


    it "sends your first story MMS." do
      Timecop.travel(2016, 6, 22, 17, 15, 0) #on MONDAY!
      @user = User.create(phone: "444", time: SomeWorker::DEFAULT_TIME, days_per_week: 2)
      Timecop.travel(2016, 6, 23, 17, 24, 0) #on TUESDAY.

      Timecop.scale(960) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain

        sleep SLEEP_960
      end

      @user.reload 



      expect(Helpers.getMMSarr).to eq(Message.getMessageArray[0].getMmsArr)
      expect(Helpers.getMMSarr).not_to eq(nil)
    end


   it "sends your first story SMS." do
      Timecop.travel(2016, 6, 22, 17, 15, 0) #on MONDAY!
      @user = User.create(phone: "444", time: SomeWorker::DEFAULT_TIME, days_per_week: 2)
      Timecop.travel(2016, 6, 23, 17, 24, 0) #on TUESDAY.

      Timecop.scale(960) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain

        sleep SLEEP_960
      end
      @user.reload 


      expect(Helpers.getSMSarr).to eq([Message.getMessageArray[0].getSMS])
      expect(Helpers.getSMSarr).not_to eq(nil)
      expect(Helpers.getSMSarr).not_to eq([])
    end


    it "sends only on right days for T-TH schedule (2)" do

      Timecop.travel(2014, 6, 21, 17, 15, 0) #on Sunday!
      @user = User.create(phone: "444", time: SomeWorker::DEFAULT_TIME, days_per_week: 2)
      
      Timecop.travel(2015, 6, 22, 17, 29, 0) #on Monday.
      expect(SomeWorker.sendStory?("444")).to be(false)

      Timecop.travel(2015, 6, 23, 17, 29, 0) #on T.
      expect(SomeWorker.sendStory?("444")).to be(true)

      Timecop.travel(2015, 6, 24, 17, 29, 0) #on Wed.
      expect(SomeWorker.sendStory?("444")).to be(false)

      Timecop.travel(2015, 6, 25, 17, 29, 0) #on Thurs
      expect(SomeWorker.sendStory?("444")).to be(true)

      Timecop.travel(2015, 6, 26, 17, 29, 0) #on Fri.
      expect(SomeWorker.sendStory?("444")).to be(false)

      Timecop.travel(2015, 6, 27, 17, 29, 0) #on sat.
      expect(SomeWorker.sendStory?("444")).to be(false)

      Timecop.travel(2015, 6, 28, 17, 29, 0) #on Fri.
      expect(SomeWorker.sendStory?("444")).to be(false)
  end

  it "sends only on right days for M-W-F schedule (2)" do

      Timecop.travel(2014, 6, 21, 17, 15, 0) #on Sunday!
      @user = User.create(phone: "444", time: SomeWorker::DEFAULT_TIME, days_per_week: 3)
      
      Timecop.travel(2015, 6, 22, 17, 29, 0) #on Monday.
      expect(SomeWorker.sendStory?("444")).to be(true)

      Timecop.travel(2015, 6, 23, 17, 29, 0) #on T.
      expect(SomeWorker.sendStory?("444")).to be(false)

      Timecop.travel(2015, 6, 24, 17, 29, 0) #on Wed.
      expect(SomeWorker.sendStory?("444")).to be(true)

      Timecop.travel(2015, 6, 25, 17, 29, 0) #on Thurs
      expect(SomeWorker.sendStory?("444")).to be(false)

      Timecop.travel(2015, 6, 26, 17, 29, 0) #on Fri.
      expect(SomeWorker.sendStory?("444")).to be(true)

      Timecop.travel(2015, 6, 27, 17, 29, 0) #on sat.
      expect(SomeWorker.sendStory?("444")).to be(false)

      Timecop.travel(2015, 6, 28, 17, 29, 0) #on Fri.
      expect(SomeWorker.sendStory?("444")).to be(false)
  end


    it "sends only on right days for W schedule (1)" do

      Timecop.travel(2014, 6, 21, 17, 15, 0) #on Sunday!
      @user = User.create(phone: "444", time: SomeWorker::DEFAULT_TIME, days_per_week: 1)
      
      Timecop.travel(2015, 6, 22, 17, 29, 0) #on Monday.
      expect(SomeWorker.sendStory?("444")).to be(false)

      Timecop.travel(2015, 6, 23, 17, 29, 0) #on T.
      expect(SomeWorker.sendStory?("444")).to be(false)

      Timecop.travel(2015, 6, 24, 17, 29, 0) #on Wed.
      expect(SomeWorker.sendStory?("444")).to be(true)

      Timecop.travel(2015, 6, 25, 17, 29, 0) #on Thurs
      expect(SomeWorker.sendStory?("444")).to be(false)

      Timecop.travel(2015, 6, 26, 17, 29, 0) #on Fri.
      expect(SomeWorker.sendStory?("444")).to be(false)

      Timecop.travel(2015, 6, 27, 17, 29, 0) #on sat.
      expect(SomeWorker.sendStory?("444")).to be(false)

      Timecop.travel(2015, 6, 28, 17, 29, 0) #on Fri.
      expect(SomeWorker.sendStory?("444")).to be(false)
  end



    it "has total message count properly increasing" do
      Timecop.travel(2015, 6, 22, 17, 15, 0) #on MONDAY!
      @user = User.create(phone: "444", time: SomeWorker::DEFAULT_TIME, days_per_week: 2)
      

      Timecop.travel(2015, 6, 23, 17, 20, 0) #on TUESDAY.
      Timecop.scale(960) #1/16 seconds now are two minutes



      (1..15).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end


          # require 'pry'
          # binding.pry


      @user.reload 
      expect(@user.total_messages).to eq(1)
      expect(@user.story_number).to eq(1)

      Timecop.travel(2015, 6, 24, 17, 24, 0) #on WED.
      Timecop.scale(960) #1/16 seconds now are two minutes

      # require 'pry'
      # binding.pry

      (1..15).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end
      @user.reload 
      expect(@user.total_messages).to eq(1)

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
    get 'test/900/STORY/ATT'
    @user = User.find_by(phone: "900")
    @user.reload

    mmsSoFar = FirstTextWorker::FIRST_MMS
    smsSoFar = ["StoryTime: Welcome to StoryTime, free pre-k stories by text! You'll get 2 stories/week-- the first is on the way!\n\nText HELP NOW for help, or STOP NOW to cancel.",
 FirstTextWorker::FIRST_SMS]

    FirstTextWorker.drain
    # binding.pry

    expect(Helpers.getMMSarr).to eq(mmsSoFar)
    expect(Helpers.getSMSarr).to eq(smsSoFar)

    #it properly sends the MMS and SMS on TUES
    Timecop.travel(2015, 6, 23, 17, 15, 0) #on tues!
    Timecop.scale(960) #1/16 seconds now are two minutes

    (1..20).each do 
      SomeWorker.perform_async
      SomeWorker.drain
      sleep SLEEP
    end
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
      Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!
      get 'test/900/STORY/ATT'
      @user = User.find_by(phone: "900")
      FirstTextWorker.drain
      @user.reload
      expect(@user.total_messages).to eq(1)



      Timecop.scale(960) #1/16 seconds now are two minutes
      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end
      @user.reload
      expect(@user.story_number).to eq(0)
      expect(@user.total_messages).to eq(1)



    mmsSoFar = FirstTextWorker::FIRST_MMS
    smsSoFar = ["StoryTime: Welcome to StoryTime, free pre-k stories by text! You'll get 2 stories/week-- the first is on the way!\n\nText HELP NOW for help, or STOP NOW to cancel.",
 FirstTextWorker::FIRST_SMS]

    expect(Helpers.getMMSarr).to eq(mmsSoFar)
    expect(Helpers.getSMSarr).to eq(smsSoFar)


      
      Timecop.travel(2015, 6, 23, 17, 24, 0) #on TUESDAY.
      Timecop.scale(960) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end
      @user.reload 
      expect(@user.total_messages).to eq(2)
      expect(@user.story_number).to eq(1)

    mmsSoFar.concat Message.getMessageArray[0].getMmsArr
    smsSoFar.concat [Message.getMessageArray[0].getSMS]

    expect(Helpers.getMMSarr).to eq(mmsSoFar)
    expect(Helpers.getSMSarr).to eq(smsSoFar)
    expect(Helpers.getMMSarr).not_to eq(nil)



      Timecop.travel(2015, 6, 24, 17, 24, 0) #on WED. (3:30)
      Timecop.scale(1920) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end
      @user.reload 
      expect(@user.total_messages).to eq(2)
      expect(@user.story_number).to eq(1)

    #NO CHANGE

    expect(Helpers.getMMSarr).to eq(mmsSoFar)
    expect(Helpers.getSMSarr).to eq(smsSoFar)
    expect(Helpers.getMMSarr).not_to eq(nil)


      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS. (3:52)
      Timecop.scale(960) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end
      @user.reload 


      #They're asked for their story choice during storyTime.
      smsSoFar.push SomeWorker::SERIES_CHOICES[0]
      expect(Helpers.getSMSarr).to eq(smsSoFar)

      ##registers series text well!
      expect(@user.awaiting_choice).to eq(true)
      expect(@user.next_index_in_series).to eq(0)

      get 'test/900/p/ATT'
      @user.reload

      ChoiceWorker.drain #OMG forgot this.

      expect(@user.awaiting_choice).to eq(false)
      expect(@user.series_choice).to eq("p")

      messageSeriesHash = MessageSeries.getMessageSeriesHash
      story = messageSeriesHash[@user.series_choice + @user.series_number.to_s][0]

      smsSoFar.push story.getSMS
      mmsSoFar.concat story.getMmsArr

      expect(Helpers.getMMSarr).to eq(mmsSoFar)
      expect(Helpers.getSMSarr).to eq(smsSoFar)

      @user.reload
      #properly update after choice_worker

      expect(@user.next_index_in_series).to eq(1)
      expect(@user.total_messages).to eq(3)


  end


  it "properly sends out the message about not responding with choice (on next valid day), then drops if don't respond by next" do
      Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!
      @user = User.create(phone: "555", days_per_week: 2, story_number: 1) #ready to receive story choice

      Timecop.travel(2015, 6, 23, 17, 24, 0) #on TUESDAY.
      Timecop.scale(960) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end
      @user.reload
      
      smsSoFar = [SomeWorker::SERIES_CHOICES[0]]
      expect(Helpers.getSMSarr).to eq(smsSoFar)

      Timecop.travel(2015, 6, 24, 17, 24, 0) #on WED.
      Timecop.scale(960) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end
      @user.reload

      expect(Helpers.getSMSarr).to eq(smsSoFar) #no message

      #EXPECT A DAYLATE MSG when don't respond
      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS.
      Timecop.scale(960) #1/8 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end
      @user.reload

      smsSoFar.push SomeWorker::DAY_LATE + " " + SomeWorker::NO_GREET_CHOICES[0]

      expect(Helpers.getSMSarr).to eq(smsSoFar)
      
      #valid things: 
      expect(@user.next_index_in_series).to eq(999)



      #PROPERLY DROPS THE FOOL w/ no response

      Timecop.travel(2015, 6, 26, 17, 24, 0) #on FRI.
      Timecop.scale(960) #1/8 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end
      @user.reload
      expect(Helpers.getSMSarr).to eq(smsSoFar)


      Timecop.travel(2015, 6, 27, 17, 24, 0) #on SAT.
      Timecop.scale(960) #1/8 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end
      @user.reload
      expect(Helpers.getSMSarr).to eq(smsSoFar)

      Timecop.travel(2015, 6, 30, 17, 24, 0) #on next TUES--> DAY TO DROP!
      Timecop.scale(960) #1/8 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end
      @user.reload


      smsSoFar.push SomeWorker::DROPPED
      expect(Helpers.getSMSarr).to eq(smsSoFar)
      expect(@user.subscribed).to eq(false)


      smsSoFar.each do |sms|
        puts sms
      end

    end



    it "properly delivers the next message in a series" do 
      Timecop.travel(2015, 6, 22, 17, 20, 0) #on MON. (3:52)
      @user = User.create(phone: "100", story_number: 1, days_per_week: 2)

      Timecop.travel(2015, 6, 23, 17, 24, 0) #on TUES. (3:52)
      Timecop.scale(960) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end
      @user.reload 

      expect(@user.series_number).to eq(0)

      #They're asked for their story choice during storyTime.
      smsSoFar = [SomeWorker::SERIES_CHOICES[0]]
      mmsSoFar = []
      expect(Helpers.getSMSarr).to eq(smsSoFar)

      ##registers series text well!
      expect(@user.awaiting_choice).to eq(true)
      expect(@user.next_index_in_series).to eq(0)

      get 'test/100/p/ATT'
      @user.reload
      ChoiceWorker.drain #OMG forgot this.

      expect(@user.series_number).to eq(0)

      expect(@user.awaiting_choice).to eq(false)
      expect(@user.series_choice).to eq("p")

      messageSeriesHash = MessageSeries.getMessageSeriesHash
      story = messageSeriesHash[@user.series_choice + @user.series_number.to_s][0]

      smsSoFar.push story.getSMS
      mmsSoFar.concat story.getMmsArr

      expect(Helpers.getMMSarr).to eq(mmsSoFar)
      expect(Helpers.getSMSarr).to eq(smsSoFar)

      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS. (3:52)
      Timecop.scale(960) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end
      @user.reload 

    # require 'pry'
    # binding.pry

    #SERIES ENDED, update user
      expect(@user.series_number).to eq(1)
      expect(@user.series_choice).to eq(nil)
      expect(@user.next_index_in_series).to eq(nil)


      messageSeriesHash = MessageSeries.getMessageSeriesHash
      story = messageSeriesHash["p" + "0"][1]

      smsSoFar.push story.getSMS
      mmsSoFar.concat story.getMmsArr

      expect(Helpers.getMMSarr).to eq(mmsSoFar)
      expect(Helpers.getSMSarr).to eq(smsSoFar)

      puts mmsSoFar
      puts smsSoFar
    end



 it "properly signs back up after being dropped, then STORY-responding" do
      Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!
      @user = User.create(phone: "555", days_per_week: 2, story_number: 1) #ready to receive story choice

      Timecop.travel(2015, 6, 23, 17, 24, 0) #on TUESDAY.
      Timecop.scale(960) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end
      @user.reload
      
      smsSoFar = [SomeWorker::SERIES_CHOICES[0]]
      expect(Helpers.getSMSarr).to eq(smsSoFar)

      Timecop.travel(2015, 6, 24, 17, 24, 0) #on WED.
      Timecop.scale(960) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end
      @user.reload

      expect(Helpers.getSMSarr).to eq(smsSoFar) #no message

      #EXPECT A DAYLATE MSG when don't respond
      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS.
      Timecop.scale(960) #1/8 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end
      @user.reload

      smsSoFar.push SomeWorker::DAY_LATE + " " + SomeWorker::NO_GREET_CHOICES[0]

      expect(Helpers.getSMSarr).to eq(smsSoFar)
      
      #valid things: 
      expect(@user.next_index_in_series).to eq(999)



      #PROPERLY DROPS THE FOOL w/ no response

      Timecop.travel(2015, 6, 26, 17, 24, 0) #on FRI.
      Timecop.scale(960) #1/8 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end
      @user.reload
      expect(Helpers.getSMSarr).to eq(smsSoFar)


      Timecop.travel(2015, 6, 27, 17, 24, 0) #on SAT.
      Timecop.scale(960) #1/8 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end
      @user.reload
      expect(Helpers.getSMSarr).to eq(smsSoFar)

      Timecop.travel(2015, 6, 30, 17, 24, 0) #on next TUES--> DAY TO DROP!
      Timecop.scale(960) #1/8 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end
      @user.reload


      smsSoFar.push SomeWorker::DROPPED
      expect(Helpers.getSMSarr).to eq(smsSoFar)
      expect(@user.subscribed).to eq(false)


      get 'test/555/STORY/ATT'
      @user.reload

      expect(@user.awaiting_choice).to be(true)
      expect(@user.subscribed).to be(true)


      #send the SERIES choice


      #welcome back, with series choice
      smsSoFar.push "StoryTime: Welcome back to StoryTime! We'll keep sending you free stories to read aloud." + "\n\n" + SomeWorker::NO_GREET_CHOICES[0]
      expect(Helpers.getSMSarr).to eq(smsSoFar)

      smsSoFar.each do |sms|
        puts sms
      end

      #ADD THE RESPONDING WITH STORY, CHECK THAT AWAITINGCHOICE: FALSE, AND SUBSCRIBED TRUE. THEN CHECK ACTUAL
    end


    it "re-offers choice after day-late" do
            Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!
      @user = User.create(phone: "555", days_per_week: 2, story_number: 1) #ready to receive story choice

      Timecop.travel(2015, 6, 23, 17, 24, 0) #on TUESDAY.
      Timecop.scale(960) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end
      @user.reload
      
      smsSoFar = [SomeWorker::SERIES_CHOICES[0]]
      expect(Helpers.getSMSarr).to eq(smsSoFar)

      Timecop.travel(2015, 6, 24, 17, 24, 0) #on WED.
      Timecop.scale(960) #1/16 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end
      @user.reload

      expect(Helpers.getSMSarr).to eq(smsSoFar) #no message

      #EXPECT A DAYLATE MSG when don't respond
      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS.
      Timecop.scale(960) #1/8 seconds now are two minutes

      (1..10).each do 
        SomeWorker.perform_async
        SomeWorker.drain
        sleep SLEEP_960
      end
      @user.reload

      smsSoFar.push SomeWorker::DAY_LATE + " "+ SomeWorker::NO_GREET_CHOICES[0]

      expect(Helpers.getSMSarr).to eq(smsSoFar)
      
      #valid things: 
      expect(@user.next_index_in_series).to eq(999)

      #properly sends out story WHEN they respond
      get 'test/555/p/ATT'
      @user.reload
      ChoiceWorker.drain #OMG forgot this.

      expect(@user.series_number).to eq(0)

      expect(@user.awaiting_choice).to eq(false)
      expect(@user.series_choice).to eq("p")

      messageSeriesHash = MessageSeries.getMessageSeriesHash
      story = messageSeriesHash[@user.series_choice + @user.series_number.to_s][0]

      smsSoFar.push story.getSMS
      mmsSoFar = story.getMmsArr

      expect(Helpers.getMMSarr).to eq(mmsSoFar)
      expect(Helpers.getSMSarr).to eq(smsSoFar)


      smsSoFar.each do |sms|
        puts sms
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