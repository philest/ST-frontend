ENV['RACK_ENV'] = "test"

require_relative '../../app/app.rb'

require_relative "../spec_helper"

configure do
  enable :sessions
end


require 'sinatra/r18n'

require 'capybara/rspec'
require 'rack/test'
require 'timecop'

require_relative '../../i18n/constants'
require_relative '../../helpers/sprint_helper'
require_relative '../../app/enroll'
require_relative '../../workers/main_worker'


#CONSTANTS

#NOTE: THE CARRIER PARAMA DOES NOTHING!!!! IT'S A HOAX

HELP_URL = "HELP%20NOW"
STOP_URL = "STOP%20NOW"
TEXT_URL = "TEXT"

SPRINT_QUERY_STRING = 'Sprint%20Spectrum%2C%20L%2EP%2E'


SINGLE_SPACE_LONG = ". If you can't receive picture msgs, reply TEXT for text-only stories.
Remember that looking at screens within two hours of bedtime can delay children's sleep and carry health risks, so read StoryTime earlier in the day.
Normal text rates may apply. For help or feedback, please contact our director, Phil, at 561-212-5831. Reply " + STOP + " to cancel."

NO_NEW_LINES = "If you can't receive picture msgs, reply TEXT for text-only stories. Remember that looking at screens within two hours of bedtime can delay children's sleep and carry health risks, so read StoryTime earlier in the day. Normal text rates may apply. For help or feedback, please contact our director, Phil, at 561-212-5831. Reply " + STOP + " to cancel."

SMALL_NO_NEW_LINES = "If you can't receive picture msgs, reply TEXT for text-only stories. Remember that looking at screens within two hours of bedtime can delay children's sleep and carry health risks, so read StoryTime earlier in the day."

MIX = "If you can't receive picture msgs, reply TEXT for text-only stories. Remember that looking at screens within two hours of bedtime can delay children's sleep and carry health risks, so read StoryTime earlier in the day. Normal text rates may apply. For help or feedback, please contact our director, Phil, at 561-212-5831.\nReply " + STOP + " to cancel."

MIXIER = "If you can't receive picture msgs, reply TEXT for text-only stories.\nRemember that looking at screens within two hours of bedtime can delay children's sleep and carry health risks, so read StoryTime earlier in the day. Normal text rates may apply. For help or feedback, please contact our director, Phil, at 561-212-5831.\nReply " + STOP + " to cancel."

  DEFAULT_TIME ||= Time.new(2015, 6, 21, 17, 30, 0, "-04:00").utc #Default Time: 17:30:00 (5:30PM), EST


include Text


describe 'The StoryTime App' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end


    before(:each) do
      TwilioHelper.initialize_testing_vars
      NextMessageWorker.jobs.clear
      NewTextWorker.jobs.clear
      Sidekiq::Worker.clear_all
    end

    after(:each) do
      Sidekiq::Worker.clear_all
    end


  it "routes successfully home" do
    get '/'
    expect(last_response).to be_ok
  end

  # SMS TESTS
  it "isn't there before" do
  	  expect(User.find_by_phone("555")).not_to eq("555")
  end

  it "signs up" do
  	get '/test/555/STORY/ATT'
    @user = User.find_by_phone("555")
    @user.reload
  	expect(@user.phone).to eq("555")
  end


  it "signs up different numbers" do
  	get '/test/888/STORY/ATT'
    @user = User.find_by_phone("888")
    @user.reload
  	expect(@user.phone).to eq("888")
  end

  it "sends correct sign up sms" do
  	get '/test/999/STORY/ATT' 
  	expect(TwilioHelper.getSMSarr[0]).to eq(Text::START_SMS_1 + 2.to_s + Text::START_SMS_2)
  end

  it "sends correct sign up sms" do
    get '/test/999/STORY/ATT' 

  end

  it "sends new text properly using integration testing w/ credentials" do

    TwilioHelper.smsSend("Your Test Cred worked!", "+15612125831",)

  end



  it "sends correct sign up sms to Sprint users" do
    get '/test/998/STORY/' + SPRINT_QUERY_STRING
    expect(TwilioHelper.getSMSarr[0]).to eq(Text::START_SPRINT_1 + "2" + Text::START_SPRINT_2)
  end

  describe "User" do

  	before(:each) do
 	 	  @user = User.create(phone: "444", time: DEFAULT_TIME)
  	end

      	it "has nil child birthdate value" do
      		expect(@user.child_birthdate).to eq(nil)
      	end

        it "has proper default age of 4" do
           expect(@user.child_age).to eq(4)
        end

        it "has proper default time" do
           expect(@user.time).to eq(DEFAULT_TIME)
        end

        it "has default time of 5:30" do
           expect(@user.time.hour).to eq(21)
           expect(@user.time.min).to eq(30)
           expect(@user.time.zone).to eq("UTC")

        end  

  end 


#HELP TESTS
  describe "Help tests" do
    before(:each) do
      @user = User.create(phone: "400")
    end

    #last time test
    it "registers default time well" do 
      get '/test/898/STORY/ATT'
      @user = User.find_by(phone: 898)
      @user.reload
      expect(@user.time.hour).to eq(DEFAULT_TIME.utc.hour)
      expect(@user.time.min).to eq(DEFAULT_TIME.utc.min)
    end



    it "responds to HELP NOW" do
      get "/test/400/" + HELP_URL + "/ATT"
      @user.reload
      expect(TwilioHelper.getSimpleSMS).to eq(Text::HELP_SMS_1 + "Tues/Thurs" + Text::HELP_SMS_2)
    end

    it "responds to 'help now' (non-sprint)" do
      get "/test/400/help%20now/ATT"
      expect(TwilioHelper.getSimpleSMS).to eq(Text::HELP_SMS_1 + "Tues/Thurs" + Text::HELP_SMS_2)
    end


    describe "sub test" do
      before(:each) do
        @user.update(carrier: "Sprint Spectrum, L.P.")
      end

        it "responds to HELP NOW from sprint" do
          get "/test/400/HELP%20NOW/" + SPRINT_QUERY_STRING
          expect(TwilioHelper.getSimpleSMS).to eq(Text::HELP_SPRINT_1 + "Tue/Th" + Text::HELP_SPRINT_2)
      end

    end

  end


    describe "Series" do

    it "updates series_choice" do
      app_enroll_many(["5612125839"], 'en', {Carrier: "ATT"})
      NextMessageWorker.drain

      @user = User.find_by_phone "5612125839"
      @user.update(story_number: 3, awaiting_choice: true, series_number: 0)
      @user.reload

      get '/test/5612125839/t/ATT'

      @user.reload

      expect(@user.series_choice).to eq("t")
    end

    it "good text response" do
      @user = User.create(phone: "700", story_number: 3, awaiting_choice: true, series_number: 0)
      get '/test/700/d/ATT'
      @user.reload


      expect(TwilioHelper.getSimpleSMS).to_not eq(Text::BAD_CHOICE)
    end

    it "doesn't register a letter weird choice" do
      @user = User.create(phone: "700", story_number: 3, awaiting_choice: true, series_number: 0)
      get '/test/700/X/ATT'
      @user.reload
      expect(TwilioHelper.getSimpleSMS).to eq(Text::BAD_CHOICE)
    end

    it "doesn't register a letter on a diff day" do
      @user = User.create(phone: "700", story_number: 3, awaiting_choice: true, series_number: 0)
      @user.update(series_number: 1)
      @user.reload
      get '/test/700/p/ATT'
      @user.reload
      expect(TwilioHelper.getSimpleSMS).to eq(Text::BAD_CHOICE)
    end


    it "works for uppercase" do
      @user = User.create(phone: "700", story_number: 3, awaiting_choice: true, series_number: 0)
      get '/test/700/T/ATT'

      NextMessageWorker.drain
      @user.reload

      @user.reload
      expect(TwilioHelper.getSimpleSMS).to_not eq(Text::BAD_CHOICE)
    end


    it "updates awaiting choice" do
      @user = User.create(phone: "700", story_number: 3, awaiting_choice: true, series_number: 0)
      get '/test/700/D/ATT'
      @user.reload

      NextMessageWorker.drain
      @user.reload

      expect(@user.awaiting_choice).to eq(false)
    end


    it "updates awaiting choice" do
      @user = User.create(phone: "700", story_number: 3, awaiting_choice: true, series_number: 0)
      get '/test/700/t/ATT'
      @user.reload

      NextMessageWorker.drain
      @user.reload

      expect(@user.awaiting_choice).to eq(false)
    end






    it "updates awaiting choice" do
      @user = User.create(phone: "700", story_number: 3, awaiting_choice: true, series_number: 0)
      @user.reload

      get '/test/700/p/ATT'
      @user.reload
      expect(TwilioHelper.getSimpleSMS).to eq(R18n.t.error.bad_choice)
      puts TwilioHelper.getSimpleSMS
    end




  end




      describe "STOP NOW works" do

        it "properly unsubscribes" do
          @user = User.create(phone: "5555", story_number: 0, subscribed: true)

          get '/test/5555/' + STOP_URL + "/ATT"
          @user.reload
          expect(@user.subscribed).to eq(false)
        end


        it "properly resubscribes" do
          @user = User.create(phone: "5555", story_number: 0, subscribed: true)

          get '/test/5555/' + STOP_URL + "/ATT"
          @user.reload
          get '/test/5555/STORY/ATT'
          @user.reload
          expect(@user.subscribed).to eq(true)
        end

        it "send good resubscription msg" do
          @user = User.create(phone: "666")


          get "/test/666/" + STOP_URL + "/ATT"
          @user.reload


          get '/test/666/STORY/ATT'
          @user.reload
          expect(TwilioHelper.getSimpleSMS).to eq(Text::RESUBSCRIBE_LONG)
        end


        #SPRINT tests

        it "leaves a message intact if under 160" do
          expect(Sprint.chop(Text::STOPSMS)).to eq([Text::STOPSMS])
        end

        it "seperates a longer message into two texts" do
          expect(Sprint.chop(Text::BAD_TIME_SMS).length).to eq(2)
          puts Sprint.chop(Text::BAD_TIME_SMS)
        end

        it "works for a long guy" do 
            puts Sprint.chop(Text::HELP_SMS_2)
        end

        it "works for single space long" do
            puts "\n"
            puts Sprint.chop(SINGLE_SPACE_LONG)
        end

        it "properly breaks up a 160+ chunk without newlines" do
            puts "\n"
            puts "\n"
            puts Sprint.chop(NO_NEW_LINES)
        end


        it "properly breaks up a MIX chunk without newlines" do
            puts "\n"
            puts "\n"
            puts Sprint.chop(MIX)
        end


        it "properly breaks up a MIXIER chunk without newlines" do
            puts "\n"
            puts "\n"
            puts Sprint.chop(MIXIER)
        end

      #SPRINT ACTION TESTS

        it "properly sends this as a three piece text to SPRINT" do
            @user = User.create(phone: "+15615422027", carrier: "Sprint Spectrum, L.P.")
            puts "\n"
            puts "\n"
            

            TwilioHelper.text(SINGLE_SPACE_LONG, SINGLE_SPACE_LONG, @user.phone)


            expect(TwilioHelper.getSMSarr.length).to eq(3)
            puts TwilioHelper.getSMSarr
      end

        it "properly sends long poemSMS to Sprint users as many pieces" do
          @user = User.create( phone: "+5615422025", carrier: "Sprint Spectrum, L.P.")
            puts "\n"
            puts "\n"

            require_relative '../../stories/story'
            require_relative '../../stories/storySeries'

            messageSeriesHash = MessageSeries.getMessageSeriesHash
            story = messageSeriesHash["d"+ @user.series_number.to_s][0]

            TwilioHelper.text(story.getPoemSMS, story.getPoemSMS, @user.phone)

            expect(TwilioHelper.getSMSarr.length).to_not eq(1)
            puts TwilioHelper.getSMSarr
        end


  end


    describe "Full Respond Helper" do

      before(:each) do
        User.create(phone: "+15612125833", carrier: "ATT")
        @user = User.find_by_phone "+15612125833"
      end

      it "properly fullResponds" do
        @user.reload

        TwilioHelper.fullRespond("Here's the SMS part!", ["imgur:://http: IMAGE 1"], "last")
        expect(TwilioHelper.getSMSarr).to eq ["Here's the SMS part!"]
        expect(TwilioHelper.getMMSarr).to eq ["imgur:://http: IMAGE 1"]

        puts TwilioHelper.getSMSarr
        puts TwilioHelper.getMMSarr

      end

      it "properly responds through wrapper (fullrespond)" do
        TwilioHelper.text_and_mms("BODY!", "imgur:://http lastest Image", "+15612125833")

        expect(TwilioHelper.getSMSarr).to eq ["BODY!"]
        expect(TwilioHelper.getMMSarr).to eq ["imgur:://http lastest Image"]

        puts TwilioHelper.getSMSarr
        puts TwilioHelper.getMMSarr

      end


    end







    describe "the BREAK command" do

      before(:each) do
        Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!
        User.create(phone: "+15612125833", carrier: "ATT")
        @user = User.find_by_phone "+15612125833"
      end

      it "won't send you a story that week if you're on break" do
        @user.reload
        expect(@user.subscribed).to eq true
        get '/test/+15612125833/'+Text::BREAK+"/ATT"

        expect(TwilioHelper.getSMSarr).to include(Text::START_BREAK)


        Timecop.travel(2015, 6, 23, 17, 30, 0) #on Tuesday!

        MainWorker.perform_async
        MainWorker.drain

        NextMessageWorker.drain


        expect(TwilioHelper.getMMSarr).to be_empty
        expect(TwilioHelper.getSMSarr[1..-1]).to be_empty

        Timecop.travel(2015, 6, 25, 17, 30, 0) #on Thurs!

        MainWorker.perform_async
        MainWorker.drain

        NextMessageWorker.drain


        expect(TwilioHelper.getMMSarr).to be_empty
        expect(TwilioHelper.getSMSarr[1..-1]).to be_empty

      end


      it "won't send you a story the next week if you're on break" do
        @user.reload
        expect(@user.subscribed).to eq true
        get '/test/+15612125833/'+Text::BREAK+"/ATT"

        Timecop.travel(2015, 6, 30, 17, 30, 0) #on next Tuesday!

        MainWorker.perform_async
        MainWorker.drain

        NextMessageWorker.drain

        expect(TwilioHelper.getMMSarr).to be_empty
        expect(TwilioHelper.getSMSarr[1..-1]).to be_empty

        Timecop.travel(2015, 7, 2, 17, 30, 0) #on next Thurs!

        MainWorker.perform_async
        MainWorker.drain

        NextMessageWorker.drain

        expect(TwilioHelper.getMMSarr).to be_empty
        expect(TwilioHelper.getSMSarr[1..-1]).to be_empty

      end

      ## TODO: Fix BREAK in main_worker so test passes. 

      # it "WILL send you a story the third week AFTER break" do
      #   @user.reload
      #   expect(@user.subscribed).to eq true
      #   Timecop.travel(2015, 6, 22, 16, 24, 0) #on MONDAY!

      #   get '/test/+15612125833/'+Text::BREAK+"/ATT"

      #   Timecop.travel(2015, 6, 23, 17, 30, 0) #on that Tuesday!
      
      #   MainWorker.perform_async
      #   MainWorker.drain

      #   NextMessageWorker.drain

      #   expect(TwilioHelper.getMMSarr).to be_empty
      #   expect(TwilioHelper.getSMSarr[1..-1]).to be_empty

      #   Timecop.travel(2015, 6, 25, 17, 30, 0) #on that Thursday!
      
      #   MainWorker.perform_async
      #   MainWorker.drain

      #   NextMessageWorker.drain

      #   expect(TwilioHelper.getMMSarr).to be_empty
      #   expect(TwilioHelper.getSMSarr[1..-1]).to be_empty



      #   Timecop.travel(2015, 6, 30, 17, 30, 0) #on the 2nd Tues!
      
      #   MainWorker.perform_async
      #   MainWorker.drain

      #   NextMessageWorker.drain

      #   expect(TwilioHelper.getMMSarr).to be_empty
      #   expect(TwilioHelper.getSMSarr[1..-1]).to be_empty


      #   Timecop.travel(2015, 7, 2, 17, 30, 0) #on the 2nd Thurs!
      
      #   MainWorker.perform_async
      #   MainWorker.drain

      #   NextMessageWorker.drain

      #   expect(TwilioHelper.getMMSarr).to be_empty
      #   expect(TwilioHelper.getSMSarr[1..-1]).to be_empty


      #   Timecop.travel(2015, 7, 7, 17, 30, 0) #DST on the third Tuesday!

      #   MainWorker.perform_async
      #   MainWorker.drain

      #   NextMessageWorker.drain

      #   NewTextWorker.drain

      #   expect(TwilioHelper.getMMSarr).to_not be_empty
      #   expect(TwilioHelper.getSMSarr[1..-1]).to_not be_empty
      #   expect(TwilioHelper.getSMSarr.last).to include(Text::END_BREAK)

      #   puts "here it is 1: " + TwilioHelper.getSMSarr.last


      #   Timecop.travel(2015, 7, 9, 17, 30, 0) #on third Thurs!

      #   MainWorker.perform_async
      #   MainWorker.drain

      #   NextMessageWorker.drain
      #   NewTextWorker.drain


      #   puts "here it is 2: " + TwilioHelper.getSMSarr.last


      #   expect(TwilioHelper.getMMSarr).to_not be_empty
      #   expect(TwilioHelper.getSMSarr[1..-1]).to_not be_empty
      #   expect(TwilioHelper.getSMSarr.last).to_not include(Text::END_BREAK)


      #   puts TwilioHelper.getSMSarr

      # end


        it "will include the StoryTime \'back after break \' message the first time, not the second" do
        @user.reload
        expect(@user.subscribed).to eq true
        get '/test/+15612125833/'+Text::BREAK+"/ATT"

        Timecop.travel(2015, 7, 7, 17, 30, 0) #on next Tuesday!

        MainWorker.perform_async
        MainWorker.drain

        NextMessageWorker.drain

        # to include Text::BREAK_END

        # expect(TwilioHelper.getMMSarr).to_not be_empty
        # expect(TwilioHelper.getSMSarr).to_not be_empty

        Timecop.travel(2015, 7, 9, 17, 30, 0) #on next Thurs!

        MainWorker.perform_async
        MainWorker.drain

        NextMessageWorker.drain

        # to not include Text::BREAK_END

        # expect(TwilioHelper.getMMSarr).to_not be_empty
        # expect(TwilioHelper.getSMSarr).to_not be_empty

      end


      it "sends the StoryTime \'start break \' message" do
        @user.reload
        expect(@user.subscribed).to eq true
        get '/test/+15612125833/'+Text::BREAK+"/ATT"

        # to include Text::BREAK_END

        expect(TwilioHelper.getMMSarr).to be_empty
        expect(TwilioHelper.getSMSarr).to eq [Text::START_BREAK]

      end

      it "properly updates ON_BREAK and DAYS_LEFT_ON_BREAK after break cmd" do
        @user.reload
        expect(@user.subscribed).to eq true

        expect(@user.on_break).to eq false
        expect(@user.days_left_on_break).to eq nil
        get '/test/+15612125833/'+Text::BREAK+"/ATT"

        @user.reload

        expect(@user.on_break).to eq true
        expect(@user.days_left_on_break).to eq Text::BREAK_LENGTH
        expect(@user.days_left_on_break).to eq 4

      end


    end

    describe "Signup" do 

      it "properly sends the no_signup_match message" do
      
        get '/test/555/thisisjunk/ATT' #improper sample request
       
        i18n = R18n::I18n.new('en', ::R18n.default_places)
        R18n.thread_set(i18n)

        R18n.set 'en'
        
        expect(R18n.t.error.no_signup_match).to_not eq nil
        expect(TwilioHelper.getSMSarr[0]).to eq R18n.t.error.no_signup_match
        puts  TwilioHelper.getSMSarr[0]
      end

      describe "Spanish" do 

        it "recognizes Spanish non-sprint commands" do

        app_enroll_many(["+14445556666"], 'es', {Carrier: "ATT"})

        
        i18n = R18n::I18n.new('es', ::R18n.default_places)
        R18n.thread_set(i18n)

        @user = User.find_by_phone "+14445556666" 
        @user.reload

        get '/test/+14445556666/AYUDA%20AHORA/ATT'

        expect(TwilioHelper.getSMSarr.last).to eq R18n.t.help.normal("Mar/Jue").to_s
        expect(TwilioHelper.getSMSarr.last).to eq "HC: Cuentos gratis para pre kínder en Mar/Jue. Para ayuda, llámenos al 561-212 5831.\n\nTiempo en pantalla antes de acostarse puede tener riesgos para la salud, así que lea temprano.\n\nResponder:\nTEXTO para cuentos sin picturas\nPARA para terminar"
        
        expect(@user.subscribed).to be true 
        get '/test/+14445556666/PARA/ATT'
        @user.reload
        expect(@user.subscribed).to be false 
        

        get '/test/+14445556666/FAKECMD/ATT'
        expect(TwilioHelper.getSMSarr.last).to eq R18n.t.error.no_option.to_s
        expect(TwilioHelper.getSMSarr.last).to eq "Hora del Cuento: Lo sentimos este servicio es automático. Nosotros no entendíamos eso.\n\nResponder:\nAYUDA AHORA para preguntas\nPARA para cancelar"

        get '/test/+14445556666/TEXTO/ATT'
        @user.reload
        expect(TwilioHelper.getSMSarr.last).to eq "HC: Bien, usted ahora recibe solo el texto de cada historia. ¡Espero esto ayude!"
        expect(TwilioHelper.getSMSarr.last).to eq R18n.t.mms_update

        end
      end
    end





    describe "Images" do


      it "are all uploaded properly" do

        get '/images/d1.jpg'
        expect(last_response).to be_ok

        get '/images/d_sp.jpg'
        expect(last_response).to be_ok

        get '/images/bb1.jpg'
        expect(last_response).to be_ok

        get '/images/bb2.jpg'
        expect(last_response).to be_ok

        get '/images/ch1.jpg'
        expect(last_response).to be_ok

        get '/images/ch2.jpg'
        expect(last_response).to be_ok

        get '/images/hero1.jpg'
        expect(last_response).to be_ok

        get '/images/hero2.jpg'
        expect(last_response).to be_ok

        get '/images/b1.jpg'
        expect(last_response).to be_ok

        get '/images/b2.jpg'
        expect(last_response).to be_ok

        #fake
        get '/images/nothinghere'
        expect(last_response).to_not be_ok

        get '/images/sofake.jpg'
        expect(last_response).to_not be_ok



      end



    end

    describe "Miscellaneous SMS" do

      before(:each) do 
        R18n.set 'en'

        get '/test/+156122233333/STORY/ATT'
        @user = User.find_by_phone "+156122233333" 
        @user.reload
      end 

      it 'responds to thanks' do
        #get thanks, respond sure
        get '/test/+156122233333/thanks/ATT'

        expect(TwilioHelper.getSMSarr.last).to eq R18n.t.misc.reply.sure.to_s
      end


      it 'responds to thank you' do
        get '/test/+156122233333/thank%20you/ATT'
        expect(TwilioHelper.getSMSarr.last).to eq R18n.t.misc.reply.sure.to_s
      end

      it "responds to 'who's this' " do
        get '/test/+156122233333/who%27s%20this/ATT'
        expect(TwilioHelper.getSMSarr.last).to eq R18n.t.misc.reply.who_we_are("2").to_s
      end

      it "responds to 'who is this' " do
        get '/test/+156122233333/who%20is%20this/ATT'
        expect(TwilioHelper.getSMSarr.last).to eq R18n.t.misc.reply.who_we_are("2").to_s
      end

      it "responds to 'whos this??' (qmark, apostrophe)" do 
        get '/test/+156122233333/whos%20this%3F%3F/ATT'
      end

    end

    describe "no option" do 

      it "registers no option" do 
        R18n.set 'en'

        get '/test/+156122233333/STORY/ATT'
        @user = User.find_by_phone "+156122233333" 
        @user.reload

        get '/test/+156122233333/randomSMS/ATT'

        expect(TwilioHelper.getSMSarr.last).to eq R18n.t.error.no_option.to_s

      end

      it "registers SPRINT no option" do 
        R18n.set 'en'

        get '/test/+156122233333/STORY/' + SPRINT_QUERY_STRING
        @user = User.find_by_phone "+156122233333" 
        @user.reload

        get '/test/+156122233333/randomSMS/ATT'

        expect(TwilioHelper.getSMSarr.last).to eq R18n.t.error.no_option_sprint.to_s

      end


    end

    describe "lib/set_time" do

      context "is DST" do
        
        before(:each) do
          Timecop.travel(Time.new(2015, 6, 15, 17, 30, 0, 0) \
               + Time.zone_offset('EST'))
        end
        
        it "knows it is DST" do
          expect(is_dst?).to be true 
        end
      
      end

      context "is not DST" do
        before(:each) do
          Timecop.travel(Time.new(2015, 12, 15, 17, 30, 0)\
               + Time.zone_offset('EST'))
        end
        
        it "knows it's not DST" do
          expect(is_dst?).to be false 
        end
      
      end

    end 

    describe "Session" do 

      describe 'Hash' do 
        before(:each) do
          get '/test/+15613334444/STORY/ATT'
          @user = User.find_by_phone "+15613334444" 
          get '/test/+15613334444/who%20is%20this/ATT'
          @user.reload
        end

        it "works" do
          expect(session).to_not be nil
        end

        it "has prev_body" do 
          expect(session['prev_body']).to eq "story"
          expect(session['new_body']).to eq 'who is this'
        end

        # NOTE: This functionality differs from 
        # the Twilio production session. That is 
        # user-independent. 
        it "mock is *NOT* user-independedent" do
          user_1 = create(:user, phone: 123)
          user_2 = create(:user, phone: 456)
          get '/test/123/hello/ATT'
          get '/test/456/hi/ATT'
          expect(TwilioHelper.getSMSarr[-2]).to include "sent"
        end


      end



      context "Repeat a series choice" do

        before :each do 
          Sidekiq::Testing.inline!
          @user = create(:user, 
                         phone: "123",
                         awaiting_choice: true,
                         series_choice: nil)
          @user.reload
        end 

        it "ignores the repeat" do
          get '/test/123/d/ATT'
          get '/test/123/d/ATT'
          expect(TwilioHelper.getSMSarr.count).to eq 1
        end

        it "ignores two repeats" do 
          get '/test/123/d/ATT'
          get '/test/123/d/ATT'
          get '/test/123/d/ATT'
          expect(TwilioHelper.getSMSarr.count).to eq 1
        end 

      end

      context "Get an unrecognized SMS" do
        before :each do 
          Sidekiq::Testing.inline!
          @user = create(:user, phone: "123", 
                         days_per_week: 2)
          @user.reload
          get '/test/123/who%20is%20doing%20this/ATT'
        end 


        context "next SMS is HELP command" do 
          before :each do 
            get '/test/123/HELP%20NOW/ATT'
          end

          it 'replies normally' do
            expect(TwilioHelper.getSMSarr.last).to eq(
                                   R18n.t.help.normal("Tues/Thurs").to_s)
          end
        end 

        context "SMS is not HELP command" do
          before :each do 
            get '/test/123/how%20do%20i%20use%20this/ATT'
          end

          it "reply thanking user" do
            expect(TwilioHelper.getSMSarr.last).to eq R18n.t.to_us.thanks
          end

          it "sends us an SMS" do
            # Hacky. Just looking in message list for text 
            # forwarded to us: 
            expect(TwilioHelper.getSMSarr[-2]).to include "sent"
          end
        end


      end

    end

end


