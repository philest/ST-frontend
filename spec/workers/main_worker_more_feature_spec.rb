
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
require_relative '../../workers/new_text_worker'

require_relative '../../i18n/constants'

SLEEP_SCALE = 860

SLEEP_TIME = (1/ 8.0)



SPRINT_CARRIER = "Sprint Spectrum, L.P."


describe 'MainWorker, with sleep,' do
  include Rack::Test::Methods
  include Text

  def app
    Sinatra::Application
  end


    before(:each) do
        NextMessageWorker.jobs.clear
        MainWorker.jobs.clear
        TwilioHelper.initialize_testing_vars
        Timecop.return
        TwilioHelper.testSleep
    end

    after(:each) do
      Timecop.return
      TwilioHelper.initialize_testing_vars

    end


    it "properly sends out messages to 10 users (no sleep.)" do
      Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!
      users = []

      TwilioHelper.testSleepOff

      (1..10).each do |number|
        get 'test/'+number.to_s+"/STORY/ATT"#each signs up
        user = User.find_by(phone: number)

        NextMessageWorker.drain
        user.reload

        expect(user.total_messages).to eq(1)
        expect(user.story_number).to eq(0)

        expect(TwilioHelper.getSMSarr).to eq([Text::START_SMS_1 + "2" + Text::START_SMS_2])              
        expect(TwilioHelper.getMMSarr).to eq([Text::THE_FINAL_MMS])

        users.push user

        @@twiml_sms = []
        @@twiml_mms = []
      end

      Timecop.travel(2015, 6, 23, 17, 26, 0) #on TUESDAY!
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      # TwilioHelper.testSleep

      #WORKS WIHOUT SLEEPING!
      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
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

      TwilioHelper.testSleepOff

      (1..10).each do |number|
        get 'test/'+number.to_s+"/STORY/ATT"#each signs up
        user = User.find_by(phone: number)

        NextMessageWorker.drain
        user.reload

        expect(user.total_messages).to eq(1)
        expect(user.story_number).to eq(0)

        expect(TwilioHelper.getSMSarr).to eq([Text::START_SMS_1 + "2" + Text::START_SMS_2])              
        expect(TwilioHelper.getMMSarr).to eq([Text::THE_FINAL_MMS])

        expect(user.total_messages).to eq 1

        users.push user

        @@twiml_sms = []
        @@twiml_mms = []
      end


      TwilioHelper.testSleep

      Timecop.travel(2015, 6, 23, 17, 30, 0) #on TUESDAY!
      # Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

        MainWorker.perform_async
        MainWorker.drain



        NextMessageWorker.drain

      users.each do |user|
        user.reload
        expect(user.total_messages).to eq(2)
        expect(user.story_number).to eq(1)
        puts " "+ user.phone + "passed"
      end

    end



    it "handles a single mms" do
      TwilioHelper.new_just_mms("http://i.imgur.com/Qkh15vl.png?1", "+15612125833")
      expect(TwilioHelper.getMMSarr[0]).to eq "http://i.imgur.com/Qkh15vl.png?1"
      expect(TwilioHelper.getSMSarr.empty?).to be true
    end




    it "properly walks through Bruce" do
      Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!
      get 'test/+15612129000/STORY/ATT'
      @user = User.find_by(phone: "+15612129000")
      NextMessageWorker.drain
      @user.reload
      expect(@user.total_messages).to eq(1)


      smsSoFar = [Text::START_SMS_1 + "2" + Text::START_SMS_2]
      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)


      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes
      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
     
      NextMessageWorker.drain

      @user.reload
      expect(@user.story_number).to eq(0)
      expect(@user.total_messages).to eq(1)



    mmsSoFar = [Text::THE_FINAL_MMS]
    smsSoFar = [ Text::START_SMS_1 + "2" + Text::START_SMS_2]


    NewTextWorker.drain

    expect(TwilioHelper.getMMSarr).to eq(mmsSoFar)
    expect(TwilioHelper.getSMSarr).to eq(smsSoFar)


      
      Timecop.travel(2015, 6, 23, 17, 24, 0) #on TUESDAY.
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes


      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end


      NextMessageWorker.drain
          NewTextWorker.drain

     
      @user.reload 
      expect(@user.total_messages).to eq(2)
      expect(@user.story_number).to eq(1)

    mmsSoFar.concat Message.getMessageArray[0].getMmsArr
    smsSoFar.concat [Message.getMessageArray[0].getSMS]

    expect(TwilioHelper.getMMSarr).to eq(mmsSoFar)
    expect(TwilioHelper.getSMSarr).to eq(smsSoFar)
    expect(TwilioHelper.getMMSarr).not_to eq(nil)



      Timecop.travel(2015, 6, 24, 17, 24, 0) #on WED. (3:30)
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload 
      expect(@user.total_messages).to eq(2)
      expect(@user.story_number).to eq(1)


    #NO CHANGE


    NewTextWorker.drain



    expect(TwilioHelper.getMMSarr).to eq(mmsSoFar)
    expect(TwilioHelper.getSMSarr).to eq(smsSoFar)
    expect(TwilioHelper.getMMSarr).not_to eq(nil)


      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS. (3:52)
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload 


    NewTextWorker.drain


      #They're asked for their story choice during storyTime.
      smsSoFar.push MainWorker::SERIES_CHOICES[0]
      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)

      ##registers series text well!
      expect(@user.awaiting_choice).to eq(true)
      expect(@user.next_index_in_series).to eq(0)

      

      get 'test/+15612129000/m/ATT'
      @user.reload



      NextMessageWorker.drain #OMG forgot this.

      expect(@user.awaiting_choice).to eq(false)
      expect(@user.series_choice).to eq("m")

      messageSeriesHash = MessageSeries.getMessageSeriesHash
      story = messageSeriesHash[@user.series_choice + @user.series_number.to_s][0]

      smsSoFar.push story.getSMS
      mmsSoFar.concat story.getMmsArr

      expect(TwilioHelper.getMMSarr).to eq(mmsSoFar)
      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)

      @user.reload
      #properly update after choice_worker

      expect(@user.next_index_in_series).to eq(1)
      expect(@user.total_messages).to eq(3)

      puts TwilioHelper.getMMSarr 
      puts TwilioHelper.getSMSarr 

  end













    # it "blocks properly: sending the second message to the 1st person BEFORE the 1st message to 21st person." do
    #         Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!
    #   users = []

    #   TwilioHelper.testSleepOff

    #   (1..25).each do |number|
    #     get 'test/'+number.to_s+"/STORY/ATT"#each signs up
    #     user = User.find_by(phone: number)

    #     NextMessageWorker.drain
    #     user.reload

    #     expect(user.total_messages).to eq(1)
    #     expect(user.story_number).to eq(0)

    #     expect(TwilioHelper.getSMSarr).to eq([Text::START_SMS_1 + "2" + Text::START_SMS_2,
    #                                     FirstTextWorker::FIRST_SMS])              
    #     expect(TwilioHelper.getMMSarr).to eq(FIRST_MMS)

    #     expect(user.total_messages).to eq 1

    #     users.push user

    #     @@twiml_sms = []
    #     @@twiml_mms = []
    #   end


    #   TwilioHelper.testSleep
    #   # require 'pry'
    #   # binding.pry 

    #   Timecop.travel(2015, 6, 23, 17, 30, 0) #on TUESDAY!
    #   # Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

    #     MainWorker.perform_async
    #     MainWorker.drain

    #     NextMessageWorker.drain

    #   users.each do |user|
    #     user.reload
    #     expect(user.total_messages).to eq(2)
    #     expect(user.story_number).to eq(1)
    #     puts " "+ user.phone + "passed"
    #   end
    # end

    

    #It works for 
    it "properly sends out messages to 10 users (sleep!)" do
    Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!
    users = []

    TwilioHelper.testSleepOff



    (11..20).each do |number|
      get 'test/'+"+156121258"+number.to_s+"/STORY/ATT"#each signs up
      user = User.find_by(phone: "+156121258"+number.to_s)




      NextMessageWorker.drain
      user.reload

      expect(user.total_messages).to eq(1)
      expect(user.story_number).to eq(0)





      expect(TwilioHelper.getSMSarr).to eq([Text::START_SMS_1 + "2" + Text::START_SMS_2])              
      expect(TwilioHelper.getMMSarr).to eq([Text::THE_FINAL_MMS])

      expect(user.total_messages).to eq 1

      users.push user

      @@twiml_sms = []
      @@twiml_mms = []

      #prime to get text choice
      user.update(story_number: 1)

    end


    TwilioHelper.testSleep

    Timecop.travel(2015, 6, 23, 17, 30, 0) #on TUESDAY!
    # Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes



      MainWorker.perform_async
      MainWorker.drain




      NewTextWorker.drain

      NextMessageWorker.drain



    users.each do |user|
      user.reload
      expect(user.total_messages).to eq(1) #haven't responded
      expect(user.story_number).to eq(1)
      puts " "+ user.phone + "passed"
    end

  end




    it "properly updates after Bruce" do
      Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!
      get 'test/+15612129000/STORY/ATT'
      @user = User.find_by(phone: "+15612129000")
      NextMessageWorker.drain
      @user.reload
      expect(@user.total_messages).to eq(1)


      smsSoFar = [Text::START_SMS_1 + "2" + Text::START_SMS_2]
      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)


      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes
      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
     
      NextMessageWorker.drain

      @user.reload
      expect(@user.story_number).to eq(0)
      expect(@user.total_messages).to eq(1)



    mmsSoFar = [Text::THE_FINAL_MMS]
    smsSoFar = [ Text::START_SMS_1 + "2" + Text::START_SMS_2]


    NewTextWorker.drain

    expect(TwilioHelper.getMMSarr).to eq(mmsSoFar)
    expect(TwilioHelper.getSMSarr).to eq(smsSoFar)


      
      Timecop.travel(2015, 6, 23, 17, 24, 0) #on TUESDAY.
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes


      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end


      NextMessageWorker.drain
          NewTextWorker.drain

     
      @user.reload 
      expect(@user.total_messages).to eq(2)
      expect(@user.story_number).to eq(1)

    mmsSoFar.concat Message.getMessageArray[0].getMmsArr
    smsSoFar.concat [Message.getMessageArray[0].getSMS]

    expect(TwilioHelper.getMMSarr).to eq(mmsSoFar)
    expect(TwilioHelper.getSMSarr).to eq(smsSoFar)
    expect(TwilioHelper.getMMSarr).not_to eq(nil)



      Timecop.travel(2015, 6, 24, 17, 24, 0) #on WED. (3:30)
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload 
      expect(@user.total_messages).to eq(2)
      expect(@user.story_number).to eq(1)


    #NO CHANGE


    NewTextWorker.drain



    expect(TwilioHelper.getMMSarr).to eq(mmsSoFar)
    expect(TwilioHelper.getSMSarr).to eq(smsSoFar)
    expect(TwilioHelper.getMMSarr).not_to eq(nil)


      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS. (3:52)
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload 


    NewTextWorker.drain


      #They're asked for their story choice during storyTime.
      smsSoFar.push MainWorker::SERIES_CHOICES[0]
      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)

      ##registers series text well!
      expect(@user.awaiting_choice).to eq(true)
      expect(@user.next_index_in_series).to eq(0)

      

      get 'test/+15612129000/m/ATT'
      @user.reload



      NextMessageWorker.drain #OMG forgot this.

      expect(@user.awaiting_choice).to eq(false)
      expect(@user.series_choice).to eq("m")

            @user.reload


      expect(@user.next_index_in_series).to eq(1)
      expect(@user.total_messages).to eq(3)
      expect(@user.story_number).to eq(1)


      messageSeriesHash = MessageSeries.getMessageSeriesHash
      story = messageSeriesHash[@user.series_choice + @user.series_number.to_s][0]

      smsSoFar.push story.getSMS
      mmsSoFar.concat story.getMmsArr

      expect(TwilioHelper.getMMSarr).to eq(mmsSoFar)
      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)

      @user.reload
      #properly update after choice_worker


      # puts TwilioHelper.getMMSarr 
      # puts TwilioHelper.getSMSarr 

      Timecop.travel(2015, 6, 30, 17, 24, 0) #on TUES. (3:52)
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload 

      NextMessageWorker.drain

      @user.reload 

      #finished series
      expect(@user.next_index_in_series).to eq(nil)
      expect(@user.total_messages).to eq(4)
      expect(@user.story_number).to eq(2)


      puts TwilioHelper.getMMSarr 
      puts TwilioHelper.getSMSarr 


      Timecop.travel(2015, 7, 2, 17, 24, 0) #on THURS . (3:52)
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload 

      NextMessageWorker.drain
      @user.reload 

      #another story done
      expect(@user.next_index_in_series).to eq(nil)
      expect(@user.total_messages).to eq(5)
      expect(@user.story_number).to eq(3)


      puts TwilioHelper.getMMSarr 
      puts TwilioHelper.getSMSarr
      puts @user.story_number


  end






end