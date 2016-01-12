### NOT updated for DST yet.


require_relative "../spec_helper"

require 'capybara/rspec'
require 'rack/test'
require 'timecop'

require 'sinatra/r18n'

require 'time'
require_relative '../../lib/set_time'

require 'active_support/all'

#TEMPORARY 
require_relative '../../app/app.rb'

require_relative '../../app/enroll'

require_relative '../../helpers/twilio_helper'
require_relative '../../stories/story'
require_relative '../../stories/storySeries'

require_relative '../../workers/main_worker'
require_relative '../../workers/new_text_worker'

require_relative '../../i18n/constants'

# Constant for time conversion.
SIDETIQ_CONVERSION = 216000

SLEEP = (1.0 / 16.0) 




SLEEP_SCALE = 860

SLEEP_TIME = (1/ 8.0)


DEFAULT_TIME ||= Time.new(2015, 6, 21, 17, 30, 0, "-04:00").utc #Default Time: 17:30:00 (5:30PM), EST



describe 'MainWorker' do
  include Rack::Test::Methods
  include Text

  def app
    Sinatra::Application
  end


    before(:each) do
        MainWorker.jobs.clear
        NextMessageWorker.jobs.clear
        NewTextWorker.jobs.clear
        TwilioHelper.initialize_testing_vars
        Timecop.return
        Sidekiq::Testing.inline!
    end

    after(:each) do
      NextMessageWorker.jobs.clear
      Timecop.return
      Sidekiq::Testing.inline!
    end

    describe "Sidekiq testing" do 

      it "properly enques a MainWorker" do
        expect(MainWorker.jobs.size).to eq(0)
        Sidekiq::Testing.fake! { MainWorker.perform_async } 
        expect(MainWorker.jobs.size).to eq(1)
      end

      it "starts with no enqued workers" do
        expect(MainWorker.jobs.size).to eq(0)
      end
    end 

    describe "Sidetiq" do

      it "has 2 min between recurrences" do 
        interval =  (MainWorker.next_scheduled_occurrence - 
                      MainWorker.last_scheduled_occurrence)
        expect(interval / SIDETIQ_CONVERSION).to be_within(0.3).of(2.0)
      end

      it "simulates recurring" do
        Sidekiq::Testing.fake!
        # Set current time to Sept, 1 2015, 10:00:00 AM
        # at this instant.
        #   - allow to move forward
        Timecop.travel(2015, 9, 1, 10, 0, 0)
        Timecop.scale(1920) 
        # 1/16 seconds now are two minutes

        # Every two minutes, MainWorker runs. 
        (1..12).each do 
          expect(MainWorker.jobs.size).to eq(0)
          MainWorker.perform_async
          expect(MainWorker.jobs.size).to eq(1)
          MainWorker.drain
          sleep SLEEP
        end
      end

    end

    describe "sendStory?" do 

      context "when enrolled last Sunday" do
        before :each do
          Timecop.travel(2015, 6, 21, 17, 30, 0) #on prev Sun!
          @user = create(:user, 
                        phone: 444,
                        time: TIME_DST,
                        total_messages: 4,
                        created_at: Time.now)
        end

        it "works at time" do
          Timecop.travel(2015, 6, 23, 17, 30, 0) #on Tuesday!
          expect(MainWorker.sendStory?("444", Time.now.utc)).to be true
        end

        it "doesn't work when past time by one minute" do
          Timecop.travel(2015, 6, 23, 17, 31, 0) #on Tuesday!
          expect(MainWorker.sendStory?("444", Time.now.utc)).to be(false)
        end


        it "doesn't work two minutes early" do            
          Timecop.travel(2015, 6, 23, 17, 28, 0) #on Tuesday.
          expect(MainWorker.sendStory?("444", Time.now.utc)).to be(false)
        end


        it "works one min early" do            
          Timecop.travel(2015, 6, 23, 17, 29, 0) #on Tuesday.
          expect(MainWorker.sendStory?("444", Time.now.utc)).to be(true)
        end
      end

      context "when enrolled over 24 hours before" do
        before :each do
          Timecop.travel(2015, 6, 22, 17, 15, 0) #on prev Sun!
          @user = create(:user, 
                        phone: 444,
                        time: TIME_DST,
                        total_messages: 4,
                        created_at: Time.now)
        end

        it "sends" do 
          Timecop.travel(2015, 6, 23, 17, 29, 0) #on Tuesday.
          expect(MainWorker.sendStory?("444", Time.now.utc)).to be(true)
        end
      end

      context "when enrolled within 24 hours before" do
        before :each do
          Timecop.travel(2015, 6, 23, 16, 15, 0) #on prev Sun!
          @user = create(:user, 
                        phone: 444,
                        time: TIME_DST,
                        total_messages: 4,
                        created_at: Time.now)
        end

        it "doesn't send" do 
          Timecop.travel(2015, 6, 23, 17, 29, 0) #still Tuesday.
          expect(MainWorker.sendStory?("444", Time.now.utc)).to be(false)
        end
      end

    end

   it "sends your first story SMS." do
      Timecop.travel(2016, 6, 22, 17, 15, 0) #on MONDAY!
      @user = User.create(phone: "444", time: TIME_DST, days_per_week: 2)
      Timecop.travel(2016, 6, 23, 17, 24, 0) #on TUESDAY.

      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain

        sleep SLEEP_TIME
      end

      NextMessageWorker.drain

      @user.reload 


      expect(TwilioHelper.getSMSarr).to eq([Message.getMessageArray[0].getSMS])
      expect(TwilioHelper.getSMSarr).not_to eq(nil)
      expect(TwilioHelper.getSMSarr).not_to eq([])
    end

    describe "Sending stories" do 

      before(:each) do
        Timecop.travel(2015, 6, 21, 17, 15, 0) #on prev Sun!
        @user = create(:user, 
                      phone: 444,
                      time: TIME_DST,
                      total_messages: 4,
                      created_at: Time.now)
      end

      context "when 2 days a week" do 

        it "sends Tuesday " do 
          Timecop.travel(2015, 6, 23, 17, 29, 0) #on Tues.
          expect(MainWorker.sendStory?("444", Time.now.utc)).to be(true)
        end

        it "sends Thursday" do 
          Timecop.travel(2015, 6, 25, 17, 29, 0) #on Tues.
          expect(MainWorker.sendStory?("444", Time.now.utc)).to be(true)
        end

        it "does not send Monday" do
          Timecop.travel(2015, 6, 22, 17, 29, 0) #on Monday.
          expect(MainWorker.sendStory?("444", Time.now.utc)).to be(false)
        end

        it "does not send Wed" do
          Timecop.travel(2015, 6, 24, 17, 29, 0) #on Monday.
          expect(MainWorker.sendStory?("444", Time.now.utc)).to be(false)
        end

        it "does not send Fri" do
          Timecop.travel(2015, 6, 26, 17, 29, 0) #on Monday.
          expect(MainWorker.sendStory?("444", Time.now.utc)).to be(false)
        end

        it "does not send Sat " do
          Timecop.travel(2015, 6, 27, 17, 29, 0) #on Monday.
          expect(MainWorker.sendStory?("444", Time.now.utc)).to be(false)
        end

        it "does not send Sun" do
          Timecop.travel(2015, 6, 28, 17, 29, 0) #on Monday.
          expect(MainWorker.sendStory?("444", Time.now.utc)).to be(false)
        end
      end

      context "when 1 day a week" do
       
        it "sends Wed" do
          Timecop.travel(2015, 6, 24, 17, 29, 0) #on Wed.
          expect(MainWorker.sendStory?("444", Time.now.utc)).to be(true)
        end

        it "doesn't send Monday" do
          Timecop.travel(2015, 6, 22, 17, 29, 0) #on Monday.
          expect(MainWorker.sendStory?("444", Time.now.utc)).to be(false)
        end
       
        it "doesn't send Tuesday " do 
          Timecop.travel(2015, 6, 23, 17, 29, 0) #on Tues.
          expect(MainWorker.sendStory?("444", Time.now.utc)).to be(false)
        end

        it "doesn't send Thursday" do 
          Timecop.travel(2015, 6, 25, 17, 29, 0) #on Thurs.
          expect(MainWorker.sendStory?("444", Time.now.utc)).to be(false)
        end

        it "doesn't send Fri" do
          Timecop.travel(2015, 6, 26, 17, 29, 0) #on Fri.
          expect(MainWorker.sendStory?("444", Time.now.utc)).to be(false)
        end

        it "doesn't send send Sat " do
          Timecop.travel(2015, 6, 27, 17, 29, 0) #on Sat.
          expect(MainWorker.sendStory?("444", Time.now.utc)).to be(false)
        end

        it "doesn't send send Sun" do
          Timecop.travel(2015, 6, 28, 17, 29, 0) #on Sun.
          expect(MainWorker.sendStory?("444", Time.now.utc)).to be(false)
        end

      end
    end

    describe "total_messages" do 
        
      context "when enrolled" do 
        before(:each) do
          Sidekiq::Testing.inline!
          Timecop.travel(2015, 6, 22, 17, 15, 0) #on Monday.
          app_enroll_many(["444"], 'en', {Carrier: "ATT"})
          @user = User.find_by_phone "444"
          @user.reload
        end

        it "is 1" do
          expect(@user.total_messages).to eq(1)
        end

        context "after second message" do 
          it "is 2" do 
            Timecop.travel(2015, 6, 23, 17, 29, 0) #on TUESDAY.
            MainWorker.perform_async
            @user.reload
            expect(@user.total_messages).to eq(2)
          end
        end

      end
    end

    describe "story_number" do 
        
      context "when enrolled" do 
        before(:each) do
          Sidekiq::Testing.inline!
          Timecop.travel(2015, 6, 22, 17, 15, 0) #on Monday.
          app_enroll_many(["444"], 'en', {Carrier: "ATT"})
          @user = User.find_by_phone "444"
          @user.reload
        end

        it "is 0" do
          expect(@user.story_number).to eq(0)
        end

        context "after second message" do 
          it "is 1" do 
            Timecop.travel(2015, 6, 23, 17, 29, 0) #on TUESDAY.
            MainWorker.perform_async
            @user.reload
            expect(@user.story_number).to eq(1)
          end
        end
      end

    end



  #series choice
  it "sends proper texts for first signup through first story and series choice!" do
    Timecop.travel(2015, 6, 22, 16, 15, 0) #on MONDAY!
    get 'test/+15559991111/STORY/ATT'
    @user = User.find_by(phone: "+15559991111")
    @user.reload

    mmsSoFar = Text::FIRST_MMS
    smsSoFar = [ Text::START_SMS_1 + "2" + Text::START_SMS_2]

    NextMessageWorker.drain

    expect(TwilioHelper.getMMSarr).to eq(mmsSoFar)
    expect(TwilioHelper.getSMSarr).to eq(smsSoFar)

    #it properly sends the MMS and SMS on TUES
    Timecop.travel(2015, 6, 23, 17, 24, 0) #on tues!
    Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

    TwilioHelper.testCred

    (1..10).each do 
      MainWorker.perform_async
      MainWorker.drain
      sleep SLEEP_TIME
    end
   
    NextMessageWorker.drain

    @user.reload 


    mmsSoFar.concat Message.getMessageArray[0].getMmsArr
    smsSoFar.concat [Message.getMessageArray[0].getSMS]

    #HACK for VERY weird error: concat changes constant.
    Text::FIRST_MMS = [Text::FIRST_MMS.first]

    expect(TwilioHelper.getMMSarr).to eq(mmsSoFar)
    expect(TwilioHelper.getSMSarr).to eq(smsSoFar)
    expect(TwilioHelper.getMMSarr).not_to eq(nil)

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
        @user.update(time: DEFAULT_TIME)
        expect(@user.total_messages).to eq(1)
        expect(@user.awaiting_choice).to eq false

        smsSoFar = [Text::START_SMS_1 + "2" + Text::START_SMS_2]
        expect(TwilioHelper.getSMSarr).to eq(smsSoFar)


        Timecop.travel(2015, 6, 22, 16, 29, 0) #on MONDAY!
        # Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes
        # (1..10).each do 
          MainWorker.perform_async
          MainWorker.drain
        #   sleep SLEEP_TIME
        # end
       
        NextMessageWorker.drain

        @user.reload
        expect(@user.story_number).to eq(0)
        expect(@user.total_messages).to eq(1)

        mmsSoFar = Text::FIRST_MMS
        smsSoFar = [ Text::START_SMS_1 + "2" + Text::START_SMS_2]


        NewTextWorker.drain
        NextMessageWorker.drain



        expect(TwilioHelper.getMMSarr).to eq(mmsSoFar)
        expect(TwilioHelper.getSMSarr).to eq(smsSoFar)


        
        Timecop.travel(2015, 6, 23, 17, 24, 0) #on TUESDAY.
        # Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

        Timecop.travel(2015, 6, 23, 17, 29, 0) #on TUESDAY.
        # (1..10).each do 
          MainWorker.perform_async
          MainWorker.drain
        #   sleep SLEEP_TIME
        # end



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
        # Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

        # (1..10).each do 

          Timecop.travel(2015, 6, 24, 17, 29, 0) #on WED. (3:30)

          MainWorker.perform_async
          MainWorker.drain
        #   sleep SLEEP_TIME
        # end
        @user.reload 
        expect(@user.total_messages).to eq(2)
        expect(@user.story_number).to eq(1)

        #NO CHANGE
        NewTextWorker.drain

        expect(TwilioHelper.getMMSarr).to eq(mmsSoFar)
        expect(TwilioHelper.getSMSarr).to eq(smsSoFar)
        expect(TwilioHelper.getMMSarr).not_to eq(nil)


        # Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS. (3:52)
        # Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

        # (1..10).each do 
          Timecop.travel(2015, 6, 25, 17, 30, 0) #on THURS. (3:30)

          MainWorker.perform_async
          MainWorker.drain
        #   sleep SLEEP_TIME
        # end
        @user.reload 


        NewTextWorker.drain

        #They're asked for their story choice during storyTime.

        smsSoFar.push R18n.t.choice.greet[0].to_s
        expect(TwilioHelper.getSMSarr).to eq(smsSoFar)

        @user.reload

        ##registers series text well!
        expect(@user.awaiting_choice).to eq(true)
        expect(@user.next_index_in_series).to eq(0)

        get 'test/+15612129000/D/ATT'
        @user.reload

        NextMessageWorker.drain #OMG forgot this.

        expect(@user.awaiting_choice).to eq(false)
        expect(@user.series_choice).to eq("d")

        messageSeriesHash = MessageSeries.getMessageSeriesHash
        story = messageSeriesHash[@user.series_choice + @user.series_number.to_s][0]

        smsSoFar.push story.getSMS
        mmsSoFar.concat story.getMmsArr

        expect(TwilioHelper.getMMSarr).to eq(mmsSoFar)
        expect(TwilioHelper.getSMSarr).to eq(smsSoFar)

        @user.reload
        #properly update after choice_worker

        expect(@user.next_index_in_series).to eq(nil) #no series
        expect(@user.total_messages).to eq(3)
  end


  it "properly sends out the message about not responding with choice (on next valid day), then drops if don't respond by next" do
      Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!
      @user = User.create(phone: "+15615422025", days_per_week: 2, story_number: 1) #ready to receive story choice
      @user.update(time: DEFAULT_TIME)

      Timecop.travel(2015, 6, 23, 17, 24, 0) #on TUESDAY.
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload
      


      NewTextWorker.drain

      NextMessageWorker.drain

      smsSoFar = [R18n.t.choice.greet[0]]
      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)

      Timecop.travel(2015, 6, 24, 17, 24, 0) #on WED.
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

    NewTextWorker.drain

      expect(TwilioHelper.getSMSarr).to eq(smsSoFar) #no message

      #EXPECT A DAYLATE MSG when don't respond
      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS.
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

          NewTextWorker.drain


      smsSoFar.push R18n.t.no_reply.day_late + " " + R18n.t.choice.no_greet[0]

      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)
      
      #valid things: 
      expect(@user.next_index_in_series).to eq(999)



      #PROPERLY DROPS THE FOOL w/ no response

      Timecop.travel(2015, 6, 26, 17, 24, 0) #on FRI.
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

    NewTextWorker.drain


      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)


      Timecop.travel(2015, 6, 27, 17, 24, 0) #on SAT.
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

    NewTextWorker.drain


      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)

      Timecop.travel(2015, 6, 30, 17, 24, 0) #on next TUES--> DAY TO DROP!
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

          NewTextWorker.drain



      smsSoFar.push R18n.t.no_reply.dropped
      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)
      expect(@user.subscribed).to eq(false)


      smsSoFar.each do |sms|
        puts sms
      end

    end



    it "properly delivers the next message in a series" do 
      Sidekiq::Testing.fake!
      Timecop.travel(2015, 6, 22, 17, 20, 0) #on MON. (3:52)
      @user = User.create(phone: "+15002125833", story_number: 1, days_per_week: 2)
      @user.update(time: DEFAULT_TIME)

      Timecop.travel(2015, 6, 23, 17, 24, 0) #on TUES. (3:52)
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
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
      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)

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

      expect(TwilioHelper.getMMSarr).to eq(mmsSoFar)
      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)

      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS. (3:52)
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
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
      mmsSoFar.concat ["http://joinstorytime.herokuapp.com/images/hero1.jpg", 
              "http://joinstorytime.herokuapp.com/images/hero2.jpg"]
      smsSoFar.concat ["StoryTime: Enjoy tonight's superhero story!\n\nWhenever you talk or play with your child, you're helping her grow into a super-reader!"]


      expect(TwilioHelper.getMMSarr).to eq(mmsSoFar)
      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)

      puts mmsSoFar
      puts smsSoFar
    end



 it "properly sends SPRINT phones story-choices that are over 160+ in many chunks" do
      Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!
      @user = User.create(phone: "+15615422025", days_per_week: 2, story_number: 1, carrier: Text::SPRINT) #ready to receive story choice
      @user.update(time: DEFAULT_TIME)
      Timecop.travel(2015, 6, 23, 17, 24, 0) #on TUESDAY.
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

      NewTextWorker.drain

      
      smsSoFar = [R18n.t.choice.greet[0]]
      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)

      Timecop.travel(2015, 6, 24, 17, 24, 0) #on WED.
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

      expect(TwilioHelper.getSMSarr).to eq(smsSoFar) #no message

      #EXPECT A DAYLATE MSG when don't respond
      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS.
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

      smsSoFar.push R18n.t.no_reply.day_late + " " + R18n.t.no_reply.day_late[0]

    NewTextWorker.drain


      expect(TwilioHelper.getSMSarr.last).to_not eq(smsSoFar.last)

      puts TwilioHelper.getSMSarr
  end







 it "properly signs back up after being dropped, then STORY-responding" do
      Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!
      @user = User.create(phone: "+15615422025", days_per_week: 2, story_number: 1) #ready to receive story choice
      @user.update(time: DEFAULT_TIME)

      Timecop.travel(2015, 6, 23, 17, 24, 0) #on TUESDAY.
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

      NewTextWorker.drain

      smsSoFar = [(R18n.t.choice.greet[0]).to_s]
      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)

      Timecop.travel(2015, 6, 24, 17, 24, 0) #on WED.
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

      expect(TwilioHelper.getSMSarr).to eq(smsSoFar) #no message

      #EXPECT A DAYLATE MSG when don't respond
      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS.
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

      smsSoFar.push R18n.t.no_reply.day_late + " " + R18n.t.choice.no_greet[0]

    NewTextWorker.drain


      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)
      
      #valid things: 
      expect(@user.next_index_in_series).to eq(999)



      #PROPERLY DROPS THE FOOL w/ no response

      Timecop.travel(2015, 6, 26, 17, 24, 0) #on FRI.
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
    NewTextWorker.drain


      @user.reload
      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)


      Timecop.travel(2015, 6, 27, 17, 24, 0) #on SAT.
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end

          NewTextWorker.drain

      @user.reload
      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)

      Timecop.travel(2015, 6, 30, 17, 24, 0) #on next TUES--> DAY TO DROP!
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

    NewTextWorker.drain


      smsSoFar.push R18n.t.no_reply.dropped.to_str
      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)
      expect(@user.subscribed).to eq(false)


      get 'test/+15615422025/STORY/ATT'
      @user.reload

      expect(@user.awaiting_choice).to be(true)
      expect(@user.subscribed).to be(true)


      #send the SERIES choice

      #welcome back, with series choice
      smsSoFar.push "StoryTime: Welcome back to StoryTime! We'll keep sending you free stories to read aloud." + "\n\n" + R18n.t.choice.no_greet[0].to_s
     

      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)

      smsSoFar.each do |sms|
        puts sms
      end

      #ADD THE RESPONDING WITH STORY, CHECK THAT AWAITINGCHOICE: FALSE, AND SUBSCRIBED TRUE. THEN CHECK ACTUAL
    end


    it "re-offers choice after day-late" do
      Sidekiq::Testing.fake!
      Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!
      @user = User.create(phone: "+15615422025", days_per_week: 2, story_number: 1) #ready to receive story choice
      @user.update(time: DEFAULT_TIME)

      Timecop.travel(2015, 6, 23, 17, 24, 0) #on TUESDAY.
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload
      
            NewTextWorker.drain

      smsSoFar = [R18n.t.choice.greet[0]]
      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)

      Timecop.travel(2015, 6, 24, 17, 24, 0) #on WED.
      Timecop.scale(SLEEP_SCALE) #1/16 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

      expect(TwilioHelper.getSMSarr).to eq(smsSoFar) #no message

      #EXPECT A DAYLATE MSG when don't respond
      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS.
      Timecop.scale(SLEEP_SCALE) #1/8 seconds now are two minutes

      (1..10).each do 
        MainWorker.perform_async
        MainWorker.drain
        sleep SLEEP_TIME
      end
      @user.reload

          NewTextWorker.drain


      smsSoFar.push R18n.t.no_reply.day_late + " "+ R18n.t.choice.no_greet[0]

      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)
      
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

      expect(TwilioHelper.getMMSarr).to eq(mmsSoFar)
      expect(TwilioHelper.getSMSarr).to eq(smsSoFar)


      smsSoFar.each do |sms|
        puts sms
      end
    end

    #TODO
    it "doesn't send story after you just text sample" do
    end

    it "properly assigns the first 10 then 20-300 peeps" do
      
      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS.

      MainWorker.perform_async
      MainWorker.drain


      (1..20).each do |num|
       expect(wait = MainWorker.getWait(MainWorker::STORY)).to eq(num)
       puts wait
      end

      (21..40).each do |num|

       expect(wait = MainWorker.getWait(MainWorker::STORY)).to eq(num + TwilioHelper::MMS_WAIT*2 )
       expect(wait).to eq(num + 40 )
       puts wait

      end

      (41..60).each do |num|
       expect(wait = MainWorker.getWait(MainWorker::STORY)).to eq(num + TwilioHelper::MMS_WAIT*4 )
       expect(wait).to eq(num + 80 )
       puts wait
      end


      MainWorker.perform_async
      MainWorker.drain

      time_sent = []

      (1..800).each do |num|
       expect(time_sent.include? (wait = MainWorker.getWait(MainWorker::STORY))).to be false
        time_sent.push wait

        expect(time_sent.include? wait + TwilioHelper::MMS_WAIT).to be false
        time_sent.push wait + TwilioHelper::MMS_WAIT

        expect(time_sent.include? wait + TwilioHelper::MMS_WAIT*2).to be false
        time_sent.push wait + TwilioHelper::MMS_WAIT*2
      end

      puts time_sent.sort



    end



    it "properly assigns the first 10 then 20-300 peeps" do
      
      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS.

      MainWorker.perform_async
      MainWorker.drain


      (1..20).each do |num|
       expect(wait = MainWorker.getWait(MainWorker::TEXT)).to eq(num )
       puts wait
      end

      (1..20).each do |num|
       expect(wait = MainWorker.getWait(MainWorker::STORY)).to eq(TwilioHelper::MMS_WAIT*2 + num + 20)
       puts wait
      end

      (21..40).each do |num|
        expect(wait = MainWorker.getWait(MainWorker::TEXT)).to eq(20 + num + TwilioHelper::MMS_WAIT*4) 
        puts wait
      end

      (21..40).each do |num|
        expect(wait = MainWorker.getWait(MainWorker::STORY)).to eq(40 + num + TwilioHelper::MMS_WAIT*6) 
        puts wait
      end


      # (41..60).each do |num|
      #  expect(wait = MainWorker.getWait(MainWorker::TEXT)).to eq(num + TwilioHelper::MMS_WAIT*4 )
      #  expect(wait).to eq(num + 80 )
      #  puts wait
      # end


      MainWorker.perform_async
      MainWorker.drain

      time_sent = []

      puts '400 trial'

      (1..400).each do |num|

        if num % 2 == 0
          type = MainWorker::STORY
        else
          type = MainWorker::TEXT
        end


       expect(time_sent.include? (wait = MainWorker.getWait(type))).to be false
        time_sent.push wait

        if type == MainWorker::STORY
          expect(time_sent.include? wait + TwilioHelper::MMS_WAIT).to be false
          time_sent.push wait + TwilioHelper::MMS_WAIT

          expect(time_sent.include? wait + TwilioHelper::MMS_WAIT*2).to be false
          time_sent.push wait + TwilioHelper::MMS_WAIT*2
        end

        puts wait
      end

      puts time_sent.sort

    end

    it "registers locale and sends correct translation" do 

      Sidekiq::Testing.inline!

      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS.
      app_enroll_many(["+15612125833"], 'es', {Carrier: "ATT"})

      @user = User.find_by_phone "+15612125833"
      


      #set up for "no_reply" message
      @user.update(awaiting_choice: false)
      @user.update(story_number: 1)
      @user.update(next_index_in_series: nil)

      Timecop.travel(2016, 6, 23, 17, 30, 0) #First Story Received (THURSDAY!).

      MainWorker.perform_async


      #set as English
      i18n = R18n::I18n.new('en', ::R18n.default_places)
      R18n.thread_set(i18n)


      expect(TwilioHelper.getSMSarr.last).to_not eq R18n.t.choice.greet[0]
      expect(TwilioHelper.getSMSarr.last).to eq "Hora del Cuento: Hi! Ask your child if they want a story about Tim's cleanup or about a dinosaur party.\n\nReply 't' for Tim or 'd' for dinos."


      ######### Spanish
     
      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS.
      app_enroll_many(["+15612125834"], 'es', {Carrier: "ATT"})

      @user = User.find_by_phone "+15612125834"

              #set up for "greet choice" message
      @user.update(awaiting_choice: false)
      @user.update(story_number: 1)
      @user.update(next_index_in_series: nil)

      Timecop.travel(2016, 6, 23, 17, 30, 0) #First Story Received.
  
      MainWorker.perform_async


      #set as Spanish
      i18n = R18n::I18n.new('es', ::R18n.default_places)
      R18n.thread_set(i18n)

      expect(TwilioHelper.getSMSarr.last).to eq R18n.t.choice.greet[0]


      #it works for a different locale 
      Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS.
      app_enroll_many(["+15612125835"], 'en', {Carrier: "ATT"})

      @user = User.find_by_phone "+15612125835"

              #set up for "greet choice" message
      @user.update(awaiting_choice: false)
      @user.update(story_number: 1)
      @user.update(next_index_in_series: nil)

      Timecop.travel(2016, 6, 23, 17, 30, 0) #First Story Received.
  
      MainWorker.perform_async

      #set as English
      i18n = R18n::I18n.new('en', ::R18n.default_places)
      R18n.thread_set(i18n)

      expect(TwilioHelper.getSMSarr.last).to eq R18n.t.choice.greet[0]
      expect(TwilioHelper.getSMSarr.last).to eq "StoryTime: Hi! Ask your child if they want a story about Tim's cleanup or about a dinosaur party.\n\nReply 't' for Tim or 'd' for dinos."

    end

    describe "when NON DST" do 

      it "sends at right EST time" do 
      Timecop.travel(2015, 11, 21, 17, 30, 0) #on prev Sun!

      @user = User.create(phone: "444", time: TIME_NO_DST, days_per_week: 2, total_messages: 4)
        
      Timecop.travel(2015, 11, 24, 17, 29, 0) #on Tuesday!
      time = Time.now.utc

      expect(MainWorker.sendStory?("444", time)).to be(true)

      end 

    end

    describe "Series choice parsing" do 

      it 'recognizes "t for Tim" as choice t' do
        Sidekiq::Testing.fake!
        Timecop.travel(2015, 6, 22, 17, 20, 0) #on MON. (3:52)
        @user = User.create(phone: "+15002125833", story_number: 1, 
                           awaiting_choice: true, days_per_week: 2,
                                           next_index_in_series: 0)
        @user.update(time: DEFAULT_TIME)

        get 'test/+15002125833/t%20for%20Tim/ATT'
        @user.reload

        expect(@user.series_number).to eq(0) #no series

        expect(@user.awaiting_choice).to eq(false)
        expect(@user.series_choice).to eq("t")

      end

      it 'recognizes "\'t\' for Tim" as choice t' do
        Sidekiq::Testing.fake!
        Timecop.travel(2015, 6, 22, 17, 20, 0) #on MON. (3:52)
        @user = User.create(phone: "+15002125833", story_number: 1, 
                           awaiting_choice: true, days_per_week: 2,
                                           next_index_in_series: 0)
        @user.update(time: DEFAULT_TIME)

        get 'test/+15002125833/%27t%27%20for%20Tim/ATT'
        @user.reload

        expect(@user.series_number).to eq(0) #no series

        expect(@user.awaiting_choice).to eq(false)
        expect(@user.series_choice).to eq("t")

      end

      it 'recognizes "t" for Tim" as choice t' do
        Sidekiq::Testing.fake!
        Timecop.travel(2015, 6, 22, 17, 20, 0) #on MON. (3:52)
        @user = User.create(phone: "+15002125833", story_number: 1, 
                           awaiting_choice: true, days_per_week: 2,
                                           next_index_in_series: 0)
        @user.update(time: DEFAULT_TIME)

        get 'test/+15002125833/%22t%22%20for%20Tim/ATT'
        @user.reload

        expect(@user.series_number).to eq(0) #no series

        expect(@user.awaiting_choice).to eq(false)
        expect(@user.series_choice).to eq("t")

      end

        
      it 'recognizes "dino" as choice d' do
        Sidekiq::Testing.fake!
        Timecop.travel(2015, 6, 22, 17, 20, 0) #on MON. (3:52)
        @user = User.create(phone: "+15002125833", story_number: 1, 
                           awaiting_choice: true, days_per_week: 2,
                                           next_index_in_series: 0)
        @user.update(time: DEFAULT_TIME)

        get 'test/+15002125833/dino/ATT'
        @user.reload

        expect(@user.series_number).to eq(0) #no series

        expect(@user.awaiting_choice).to eq(false)
        expect(@user.series_choice).to eq("d")

      end

      it 'sends default story for unexpected choice' do
        Sidekiq::Testing.fake!
        Timecop.travel(2015, 6, 22, 17, 20, 0) #on MON. (3:52)
        @user = User.create(phone: "+15002125833", story_number: 1, 
                           awaiting_choice: true, days_per_week: 2,
                                           next_index_in_series: 0)
        @user.update(time: DEFAULT_TIME)

        get 'test/+15002125833/okay/ATT'
        @user.reload

        expect(@user.series_number).to eq(0) #no series

        expect(@user.awaiting_choice).to eq(false)
        expect(@user.series_choice).to eq("t")

      end

      it 'sends default story for unexpected choice' do
        Sidekiq::Testing.fake!
        Timecop.travel(2015, 6, 22, 17, 20, 0) #on MON. (3:52)
        @user = User.create(phone: "+15002125833", story_number: 1, 
                           awaiting_choice: true, days_per_week: 2,
                                           next_index_in_series: 0)
        @user.update(time: DEFAULT_TIME)

        get 'test/+15002125833/okay/ATT'
        @user.reload

        expect(@user.series_number).to eq(0) #no series

        expect(@user.awaiting_choice).to eq(false)
        expect(@user.series_choice).to eq("t")

      end

      it 'registers dropped user who texts choice' do 
        Sidekiq::Testing.fake!
        Timecop.travel(2015, 6, 22, 17, 20, 0) #on MON. (3:52)

        #just DROPPED. 
        @user = User.create(phone: "+15002125833", subscribed: false,
                             story_number: 1, awaiting_choice: false,
                         days_per_week: 2, next_index_in_series: 999)

        get 'test/+15002125833/D/ATT'
        @user.reload
        expect(@user.subscribed).to be true

        expect(@user.awaiting_choice).to be false
        expect(@user.next_index_in_series).to eq 0
        expect(@user.series_choice).to eq 'd'
      end

      it 'sends story dropped user who texts choice' do 
        Sidekiq::Testing.fake!
        Timecop.travel(2015, 6, 22, 17, 20, 0) #on MON. (3:52)

        #just DROPPED. 
        @user = User.create(phone: "+15002125833", subscribed: false,
                             story_number: 1, awaiting_choice: false,
                         days_per_week: 2, next_index_in_series: 999)

        get 'test/+15002125833/D/ATT'
        @user.reload

        mmsSoFar = []

        messageSeriesHash = MessageSeries.getMessageSeriesHash
        story = messageSeriesHash[@user.series_choice + @user.series_number.to_s][0]
        mmsSoFar.concat story.getMmsArr

        NextMessageWorker.drain
        expect(TwilioHelper.getMMSarr).to eq mmsSoFar
      end




    end


end