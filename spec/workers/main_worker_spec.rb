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


  def through_sent_choices(properSMS, properMMS, phone, carrier, test_it)
          # Monday
      Timecop.travel(2015, 6, 22, 16, 15, 0) #on Monday.
      app_enroll_many([phone], 'en', {Carrier: carrier})
      @user = User.find_by_phone phone
      @user.reload

      # Get first MMS, with introductory SMS
      @properMMS = [Text::FIRST_MMS.first]

      if carrier == Text::SPRINT
        @properSMS = [R18n.t.start.sprint("2").to_str]
      else
        @properSMS = [R18n.t.start.normal("2").to_str]
      end

      if test_it
        expect(TwilioHelper.getMMSarr).to eq(@properMMS)
        expect(TwilioHelper.getSMSarr).to eq(@properSMS)
      end

      #Tuesday
      Timecop.travel(2015, 6, 23, 17, 29, 0) #on tues!
      MainWorker.perform_async
      
      # Get full story MMS, with its SMS
      @properMMS.concat Message.getMessageArray[0].getMmsArr
      @properSMS.concat [Message.getMessageArray[0].getSMS]

      if test_it
        expect(TwilioHelper.getMMSarr).to eq(@properMMS)
        expect(TwilioHelper.getSMSarr).to eq(@properSMS)
        expect(TwilioHelper.getMMSarr).not_to eq(nil)
      end

      # Wednesday
      Timecop.travel(2015, 6, 24, 17, 29, 0) #on WED. (3:30)
      MainWorker.perform_async
      @user.reload
      # No change. 
      if test_it
        expect(@user.total_messages).to eq 2
      end

      # Thursday
      Timecop.travel(2015, 6, 25, 17, 30, 0) #on THURS. (3:30)
      MainWorker.perform_async
      @user.reload 

      #They're asked for their story choice during storyTime.
      @properSMS.push R18n.t.choice.greet[0].to_s
     
      if test_it
        expect(TwilioHelper.getSMSarr).to eq(@properSMS)
        expect(@user.awaiting_choice).to eq(true)
        expect(@user.next_index_in_series).to eq(0)
      end
      ##registers series text well!
  end


  def make_choice(properSMS, properMMS, phone, letter_choice, carrier, test_it)
    story = ''
    Sidekiq::Testing.fake! do 
      get "test/#{phone}/#{letter_choice}/#{carrier}"
      @user.reload

      if test_it
        expect(@user.awaiting_choice).to eq(false)
        expect(@user.series_choice).to eq(letter_choice.downcase)
      end

      messageSeriesHash = MessageSeries.getMessageSeriesHash
      story = messageSeriesHash[ @user.series_choice + @user.series_number.to_s][0]
    end

    #because of fake
    NextMessageWorker.drain
    NewTextWorker.drain

    @properSMS.push story.getSMS
    @properMMS.concat story.getMmsArr

    @user.reload

    if test_it
      expect(TwilioHelper.getMMSarr).to eq(@properMMS)
      expect(TwilioHelper.getSMSarr).to eq(@properSMS)
      #properly updates user date 
      expect(@user.next_index_in_series).to eq(nil) #no series
      expect(@user.total_messages).to eq(3)
    end

  end

  def to_dropped(properSMS, properMMS, phone, carrier)
    @properSMS = []
    @properMMS = [] 
    through_sent_choices(@properSMS, @properMMS, '+15612129999', 'ATT', false)

    # Sunday
    # No change. 
    Timecop.travel(2015, 6, 28, 17, 29, 0) #on Sunday
    MainWorker.perform_async
    expect(TwilioHelper.getSMSarr).to eq @properSMS

    # Tuesday (next valid day)
    # Get reminder
    Timecop.travel(2015, 6, 30, 17, 29, 0) #on tues, first valid day after
    MainWorker.perform_async
    @user.reload
    @properSMS.push R18n.t.no_reply.day_late + R18n.t.choice.no_greet[0]
    expect(TwilioHelper.getSMSarr).to eq(@properSMS)
    # Notes no response: 
    expect(@user.next_index_in_series).to eq(999)

    # Wed
    # No change. 
    Timecop.travel(2015, 7, 1, 17, 29, 0)  #on Wed
    MainWorker.perform_async
    @user.reload
    expect(TwilioHelper.getSMSarr).to eq @properSMS
    expect(@user.subscribed).to eq true

    #Thursday
    #PROPERLY DROPS THE FOOL: It's the next valid day.
    Timecop.travel(2015, 7, 2, 17, 29, 0)  #on Thurs
    MainWorker.perform_async
    @user.reload
    @properSMS.push R18n.t.no_reply.dropped.to_str

    expect(TwilioHelper.getSMSarr).to eq(@properSMS)
    expect(@user.subscribed).to eq(false)
  end


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
      (1..3).each do
        puts "THE SPECS BEGIN"
      end

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

  describe 'Fake' do 
    it "sends your first story SMS." do
      Timecop.travel(2016, 6, 22, 17, 15, 0) #on Monday.
      @user = User.create(phone: "444", time: TIME_DST, days_per_week: 2)
      Timecop.travel(2016, 6, 23, 17, 24, 0) #on Tuesday.

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
  end

  describe "Sending stories" do 


    context "when 2 days a week" do 
      before(:each) do
       Timecop.travel(2015, 6, 21, 17, 15, 0) #on prev Sun!
       @user = create(:user, 
                      phone: '444',
                      time: TIME_DST,
                      total_messages: 4,
                      created_at: Time.now)
      end


      it "sends Tuesday " do 
        Timecop.travel(2015, 6, 23, 17, 29, 0) #on Tues.
        expect(MainWorker.sendStory?("444", Time.now.utc)).to be(true)
      end

      it "sends Thursday" do 
        Timecop.travel(2015, 6, 25, 17, 29, 0) #on Thurs.
        expect(MainWorker.sendStory?("444", Time.now.utc)).to be(true)
      end

      it "does not send Monday" do
        Timecop.travel(2015, 6, 22, 17, 29, 0) #on Monday.
        expect(MainWorker.sendStory?("444", Time.now.utc)).to be(false)
      end

      it "does not send Wed" do
        Timecop.travel(2015, 6, 24, 17, 29, 0) #on Wed.
        expect(MainWorker.sendStory?("444", Time.now.utc)).to be(false)
      end

      it "does not send Fri" do
        Timecop.travel(2015, 6, 26, 17, 29, 0) #on Fri.
        expect(MainWorker.sendStory?("444", Time.now.utc)).to be(false)
      end

      it "does not send Sat " do
        Timecop.travel(2015, 6, 27, 17, 29, 0) #on Sat.
        expect(MainWorker.sendStory?("444", Time.now.utc)).to be(false)
      end

      it "does not send Sun" do
        Timecop.travel(2015, 6, 28, 17, 29, 0) #on Sun.
        expect(MainWorker.sendStory?("444", Time.now.utc)).to be(false)
      end
    end

    context "when 1 day a week" do
      before(:each) do
       Timecop.travel(2015, 6, 21, 17, 15, 0) #on prev Sun!
       @user = create(:user, 
                      days_per_week: 1,
                      phone: '444',
                      time: TIME_DST,
                      total_messages: 4,
                      created_at: Time.now)
      end

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
          Timecop.travel(2015, 6, 23, 17, 29, 0) #on Tuesday.
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
          Timecop.travel(2015, 6, 23, 17, 29, 0) #on Tuesday.
          MainWorker.perform_async
          @user.reload
          expect(@user.story_number).to eq(1)
        end
      end
    end

  end



  # Integration Test. 
  describe "Getting Texts" do 

    it "sends right texts up through series choice" do 

      @properSMS = []
      @properMMS = [] 
      through_sent_choices(@properSMS, @properMMS, "+15612129999", 'ATT', true)
     
      #HACK for VERY weird error: concat changes constant.
      Text::FIRST_MMS = [Text::FIRST_MMS.first]

      make_choice(@properSMS, @properMMS, '+15612129999', 'D', 'ATT', true)
      # Friday
      Timecop.travel(2015, 6, 26, 17, 30, 0) #on Fri. (3:30)
      MainWorker.perform_async
      @user.reload 
      # No change.
      expect(@user.total_messages).to eq(3)
    end 

  end

  context "when no choice made" do 
    it "reminds on first valid day, drops on second" do 
     
      @properSMS = []
      @properMMS = [] 
      to_dropped(@properSMS, @properMMS, '+15612129999', 'ATT')
    end
  end


  it "properly delivers the next message in AFTER series" do 

    @properSMS = []
    @properMMS = [] 
    through_sent_choices(@properSMS, @properMMS, '+15612129999', 'ATT', false)
   
    make_choice(@properSMS, @properMMS, '+15612129999', 't', 'ATT', true)

    @user.reload 


    #SERIES ENDED, update user
    expect(@user.series_number).to eq(1)
    expect(@user.series_choice).to eq(nil)
    expect(@user.next_index_in_series).to eq(nil)

    #Next week: Tuesday
    #Send the next story (non-series).
    Timecop.travel(2015, 7, 7, 17, 29, 0)  #on Thurs
    MainWorker.perform_async
    @user.reload

    #because one pager, hero stories
    @properMMS.concat ["http://joinstorytime.herokuapp.com/images/hero1.jpg", 
            "http://joinstorytime.herokuapp.com/images/hero2.jpg"]
    @properSMS.concat ["StoryTime: Enjoy tonight's superhero story!\n\nWhenever you talk or play with your child, you're helping her grow into a super-reader!"]


    expect(TwilioHelper.getMMSarr).to eq(@properMMS)
    expect(TwilioHelper.getSMSarr).to eq(@properSMS)

  end


  it "sends Sprint users 160-char+ choices over many SMS" do
   
    @properSMS = []
    @properMMS = [] 
    through_sent_choices(@properSMS, @properMMS, '+15612129999', Text::SPRINT, false)
   
    # The same
    expect(TwilioHelper.getSMSarr).to eq(@properSMS)

    # Tuesday
    # EXPECT A DAYLATE MSG when don't respond 
    Timecop.travel(2015, 6, 30, 17, 30, 0)
    MainWorker.perform_async
    @user.reload 

    # Broken into two chunks beause of Sprint, 
    # so will differ from properSMS by one message
    @properSMS.push R18n.t.no_reply.day_late + R18n.t.choice.no_greet[0]
    msg_difference = TwilioHelper.getSMSarr.count - @properSMS.count
    expect(msg_difference).to eq 1 

    # Proper sprint-chopped message
    expect(TwilioHelper.getSMSarr[-2]).to include "(1/2)"
    expect(TwilioHelper.getSMSarr[-2]).to include "Ask your child"
    expect(TwilioHelper.getSMSarr[-1]).to include "(2/2)"

  end

  context 'when dropped' do 
    it 'resubscribes with STORY' do 

      @properSMS = []
      @properMMS = [] 
      to_dropped(@properSMS, @properMMS, '+15612129999', 'ATT')

      get 'test/+15612129999/STORY/ATT'
      @user.reload

      expect(@user.awaiting_choice).to be(true)
      expect(@user.subscribed).to be(true)


      #send the SERIES choice

      #welcome back, with series choice
      @properSMS.push  R18n.t.stop.resubscribe.short + R18n.t.choice.no_greet[0].to_s
     
      expect(TwilioHelper.getSMSarr).to eq(@properSMS)
    end
  end

  context 'when choice is a day late' do

    it 'still sends story' do 
      @properSMS = []
      @properMMS = [] 
      through_sent_choices(@properSMS, @properMMS, '+15612129999', 'ATT', false)

      # Sunday
      # No change. 
      Timecop.travel(2015, 6, 28, 17, 29, 0) #on Sunday
      MainWorker.perform_async
      expect(TwilioHelper.getSMSarr).to eq @properSMS

      # Tuesday (next valid day)
      # Get reminder
      Timecop.travel(2015, 6, 30, 17, 29, 0) #on tues, first valid day after
      MainWorker.perform_async
      @user.reload
      @properSMS.push R18n.t.no_reply.day_late + R18n.t.choice.no_greet[0]
      expect(TwilioHelper.getSMSarr).to eq(@properSMS)
      # Notes no response: 
      expect(@user.next_index_in_series).to eq(999)

      # Wednesday
      # Makes Choice --> Gets story. 
      Timecop.travel(2015, 7, 1, 17, 29, 0)
      make_choice(@properSMS, @properMMS, '+15612129999', 't', 'ATT', false)
    end 

  end

    #TODO
    context 'after texts SAMPLE' do
      it "doesn't send story" do
        # Wednesday
        Timecop.travel(2015, 7, 1, 17, 24, 0)
        get '/test/+15612224444/SAMPLE/ATT'
        @user = User.find_by_phone '+15612224444'
        expect(@user.subscribed).to be false

        Timecop.travel(2015, 7, 2, 17, 29, 0)
        MainWorker.perform_async
        @user.reload
        expect(TwilioHelper.getSMSarr.count).to eq 1
      end

    end

    describe 'Wait time' do 
      # TODO Make sense of this, refactor. 
      it "staggers" do 
        Timecop.travel(2015, 6, 25, 17, 24, 0) #on THURS.
        MainWorker.perform_async

        (1..20).each do |num|
         expect(wait = MainWorker.getWait(MainWorker::STORY)).to eq(num)
        end

        (21..40).each do |num|

         expect(wait = MainWorker.getWait(MainWorker::STORY)).to eq(num + TwilioHelper::MMS_WAIT*2 )
         expect(wait).to eq(num + 40 )
        end

        (41..60).each do |num|
         expect(wait = MainWorker.getWait(MainWorker::STORY)).to eq(num + TwilioHelper::MMS_WAIT*4 )
         expect(wait).to eq(num + 80 )
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

        # puts time_sent.sort
      end
    end

    it "registers locale and sends correct translation" do 

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

      it 'sends story to dropped user who texts choice' do 
        Sidekiq::Testing.fake!
        Timecop.travel(2015, 6, 22, 17, 20, 0) #on MON. (3:52)

        #just DROPPED. 
        @user = User.create(phone: "+15002125833", subscribed: false,
                             story_number: 1, awaiting_choice: false,
                         days_per_week: 2, next_index_in_series: 999)

        get 'test/+15002125833/D/ATT'
        @user.reload

        properMMS = []

        messageSeriesHash = MessageSeries.getMessageSeriesHash
        story = messageSeriesHash[@user.series_choice + @user.series_number.to_s][0]
        properMMS.concat story.getMmsArr

        NextMessageWorker.drain
        expect(TwilioHelper.getMMSarr).to eq properMMS
      end




    end


end