ENV['RACK_ENV'] = "test"

require_relative "./spec_helper"


require 'capybara/rspec'
require 'rack/test'


#CONSTANTS

#NOTE: THE CARRIER PARAMA DOES NOTHING!!!! IT'S A HOAX

HELP_URL = "HELP%20NOW"
STOP_URL = "STOP%20NOW"
TEXT_URL = "TEXT"

SPRINT_QUERY_STRING = 'Sprint%20Spectrum%2C%20L%2EP%2E'

RESUBSCRIBE_LONG = "StoryTime: Welcome back to StoryTime! We'll keep sending you free stories to read aloud, continuing from where you left off."

WRONG_BDAY_FORMAT = "We did not understand what you typed. Reply with child's birthdate in MMDDYY format. For questions, reply " + HELP + ". To cancel, reply " + STOP + "."

TOO_YOUNG_SMS = "StoryTime: Sorry, for now we only have msgs for kids ages 3 to 5. We'll contact you when we expand soon! Or reply with birthdate in MMYY format."

MMS_UPDATE = "Okay, you'll now receive just the text of each story. Hope this helps!"

HELP_SMS_1 =  "StoryTime texts free kids' stories on "

HELP_SMS_2 = ". If you can't receive picture msgs, reply TEXT for text-only stories.

Remember that looking at screens within two hours of bedtime can delay children's sleep and carry health risks, so read StoryTime earlier in the day. 

Normal text rates may apply. For help or feedback, please contact our director, Phil, at 561-212-5831. Reply " + STOP + " to cancel."

HELP_SPRINT_1 = "StoryTime texts free kids' stories on "

HELP_SPRINT_2 = ". For help or feedback, contact our director, Phil, at 561-212-5831. Reply " + STOP + " to cancel."

STOPSMS = "Okay, we\'ll stop texting you stories. Thanks for trying us out! If you have any feedback, please contact our director, Phil, at 561-212-5831."

START_SMS_1 = "StoryTime: Welcome to StoryTime, free pre-k stories by text! You'll get "

START_SMS_2 = " stories/week-- the first is on the way!\n\nText " + HELP + " for help, or " + STOP + " to cancel."

START_SPRINT_1 = "Welcome to StoryTime, free pre-k stories by text! You'll get "

START_SPRINT_2 = " stories/week-- the 1st is on the way!\n\nFor help, reply HELP NOW."


TIME_SPRINT = "ST: Great, last question! When do you want to get stories (e.g. 5:00pm)? 

Screentime w/in 2hrs before bedtime can carry health risks, so please read earlier."

TIMESMS = "StoryTime: Great, last question! When do you want to receive stories (e.g. 5:00pm)? 

Screentime within 2hrs before bedtime can delay children's sleep and carry health risks, so please read earlier."

BAD_TIME_SMS = "We did not understand what you typed. Reply with your preferred time to get stories (e.g. 5:00pm). 
For questions about StoryTime, reply " + HELP + ". To stop messages, reply " + STOP + "."
  
BAD_TIME_SPRINT = "We did not understand what you typed. Reply with your preferred time to get stories (e.g. 5:00pm). Reply " + HELP + "for help."
  
REDO_BIRTHDATE = "When was your child born? For age appropriate stories, reply with your child's birthdate in MMYY format (e.g. 0912 for September 2012)."

SPRINT = "Sprint Spectrum, L.P."

NO_OPTION = "StoryTime: This service is automatic. We didn't understand what you typed. For questions about StoryTime, reply " + HELP + ". To stop messages, reply " + STOP + "."

GOOD_CHOICE = "Great, it's on the way!"

BAD_CHOICE = "StoryTime: Sorry, we didn't understand that. Reply with the letter of the story you want.

For help, reply HELP NOW."

DEFAULT_TIME = Time.new(2015, 6, 21, 17, 30, 0, "-05:00") #Default Time: 17:30:00 (5:30PM), EST



describe 'The StoryTime App' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end


    before(:each) do
      Helpers.initialize_testing_vars
      @@twiml = Helpers.getSimpleSMS
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
  	expect(User.find_by_phone("555").phone).to eq("555")
  end


  it "signs up different numbers" do
  	get '/test/888/STORY/ATT'
  	expect(User.find_by_phone("888").phone).to eq("888")
  end

  it "sends correct sign up sms" do
  	get '/test/999/STORY/ATT'
  	expect(@@twiml).to eq(START_SMS_1 + 2.to_s + START_SMS_2)
  end

  it "sends correct sign up sms to Sprint users" do
    get '/test/998/STORY/' + SPRINT_QUERY_STRING
    expect(@@twiml).to eq(START_SPRINT_1 + "2" + START_SPRINT_2)
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
           expect(@user.time.hour).to eq(17)
           expect(@user.time.min).to eq(30)
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
      expect(@@twiml).to eq(HELP_SMS_1 + "Tues and Thurs" + HELP_SMS_2)
    end

    it "responds to 'help now' (non-sprint)" do
      get "/test/400/help%20now/ATT"
      expect(@@twiml).to eq(HELP_SMS_1 + "Tues and Thurs" + HELP_SMS_2)
    end


    describe "sub test" do
      before(:each) do
        @user.update(carrier: "Sprint Spectrum, L.P.")
      end

        it "responds to HELP NOW from sprint" do
          get "/test/400/HELP%20NOW/" + SPRINT_QUERY_STRING
          expect(@@twiml).to eq(HELP_SPRINT_1 + "Tues and Thurs" + HELP_SPRINT_2)
      end

    end

  end


#BIRTHDAY REGISTRATION
  # describe "BIRTHDATE tests" do
  #   before(:each) do
  #     @user = User.create(phone: "500", set_birthdate: false) #have just received third story
  #   end

  #   it "should not register invalid birthdate" do
  #     get '/test/500/0912555/ATT'
  #     expect(@@twiml).to eq(WRONG_BDAY_FORMAT)
  #   end

  #   it "registers a custom birthdate" do
  #     get '/test/500/0911/ATT'
  #    TIME_SMS = "StoryTime: Great! Your child's birthdate is " + "09" + "/" + "11" + ". If not correct, reply REDO. If correct, enjoy your next age-appropriate story!"
  #     expect(@@twiml).to eq(TIME_SMS)
  #   end

  #   it "correctly updates age" do
  #     get '/test/500/0911/ATT'
  #     @user.reload
  #     expect(@user.child_age).to eq(3)
  #   end



  #   it "too young shouldn't be allowed in" do
  #      get '/test/500/0914/ATT'
  #     expect(@@twiml).to eq(TOO_YOUNG_SMS)
  #   end


  #   it "keeps birthdate for too young" do
  #      get '/test/500/0914/ATT'
  #      @user.reload
  #     expect(@user.child_birthdate).to eq("0914")
  #   end



  #   describe "further Bday" do
  #     before(:each) do
  #     @user.update(set_birthdate: true) #have just received third story
  #   end

  #     it "shouldn't register a birthday after it's been set" do
  #       get '/test/500/0911/ATT'
  #      TIME_SMS = "StoryTime: Great! Your child's birthdate is " + "09" + "/" + "11" + ". If not correct, reply STORY. If correct, enjoy your next age-appropriate story!"
  #       expect(@@twiml).not_to eq(TIME_SMS)
  #     end

  #   end

  # end


  #   describe "TIME tests" do
  #   before(:each) do
  #     @user = User.create(phone: "600", set_time: false) #have just received first two stories
  #   end

  #     it "registers a custom time" do
  #       get '/test/600/6:00pm/ATT'
  #       @user.reload
  #       expect(@@twiml).to eq("StoryTime: Sounds good! Your new story time is #{@user.time}. Enjoy!")
  #     end

  #     it "registers a custom time in spaced format" do
  #       get '/test/600/6:00%20pm/ATT'
  #       @user.reload
  #       expect(@@twiml).to eq("StoryTime: Sounds good! Your new story time is #{@user.time}. Enjoy!")
  #     end

  #     describe "further time tests" do
  #       before(:each) do
  #       @user.update(set_time: true) #have just received third story
  #     end

  #     it "shouldn't register a time after it's been set" do
  #       get '/test/600/6:00pm/ATT'
  #       expect(@@twiml).to eq(NO_OPTION)
  #     end

  #   end



    describe "Series" do
      before(:each) do
        @user = User.create(phone: "700", story_number: 3, awaiting_choice: true, series_number: 0)
      end

    it "updates series_choice" do
      get '/test/700/p/ATT'
      @user.reload
      expect(@user.series_choice).to eq("p")
    end

    it "good text response" do
      get '/test/700/p/ATT'
      @user.reload
      expect(@@twiml).to_not eq(BAD_CHOICE)
    end

    it "doesn't register a letter weird choice" do
      get '/test/700/X/ATT'
      @user.reload
      expect(@@twiml).to eq(BAD_CHOICE)
    end

    it "doesn't register a letter on a diff day" do
      @user.update(series_number: 1)
      @user.reload
      get '/test/700/p/ATT'
      @user.reload
      expect(@@twiml).to eq(BAD_CHOICE)
    end


    it "works for uppercase" do
      get '/test/700/P/ATT'
      @user.reload
      expect(@@twiml).to_not eq(BAD_CHOICE)
    end


    it "updates awaiting choice" do
      get '/test/700/P/ATT'
      @user.reload
      expect(@user.awaiting_choice).to eq(false)
    end


    it "updates awaiting choice" do
      @user.update(awaiting_choice: false)
      @user.reload
      get '/test/700/p/ATT'
      @user.reload
      expect(@@twiml).to eq(NO_OPTION)
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
          expect(@@twiml).to eq(RESUBSCRIBE_LONG)
        end


      end









# end







# STAGE 2 TESTS 
#   it "registers numeric age" do
#   	get '/test/111/STORY'
#   	get '/test/111/091412'
#   	expect(@@twiml).to eq("StoryTime: Great! You've got free nightly stories. Reply with your preferred time to receive stories (e.g. 6:30pm)")
#   end

#   it "registers age in words" do
#   	get '/test/222/STORY'
#   	get '/test/222/011811'
#   	expect(@@twiml).to eq("StoryTime: Great! You've got free nightly stories. Reply with your preferred time to receive stories (e.g. 6:30pm)")
#   end

#   it "rejects non-age" do
#   	get '/test/1000/STORY'
#   	get '/test/1000/badphone'
#   	expect(@@twiml).to eq("We did not understand what you typed. Please reply with your child's birthdate in MMDDYY format. For questions about StoryTime, reply HELP. To Stop messages, reply STOP.")
#   end

# # STAGE 3 TESTS
# 	it "registers timepm" do
# 		get '/test/833/STORY'
# 		get '/test/833/091412'
# 		get "/test/833/6:00pm"
# 		expect(@@twiml).to eq("StoryTime: Sounds good! We'll send you and your child a new story each night at 6:00pm.")
# 	end


#   it "registers time then pm" do
#     get '/test/844/STORY'
#     get '/test/844/091412'
#     get '/test/844/6:00%20pm'
#     expect(@@twiml).to eq("StoryTime: Sounds good! We'll send you and your child a new story each night at 6:00pm.")
#   end


# 	it "rejects a bad time registration" do
# 		get '/test/633/STORY'
# 		get '/test/633/091412'
# 		get '/test/633/boo'
# 		expect(@@twiml).to eq("(1/2)We did not understand what you typed. Reply with your child's preferred time to receive stories (e.g. 6:30pm).")	
# 	end


# # PASSED ALL STAGES TESTS
# 	it "doesn't recognize further commands" do
# 		get '/test/488/STORY'
# 		get '/test/488/091412'
# 		get '/test/488/6:00pm'
# 		get '/test/488/hello'
# 		expect(@@twiml).to eq("This service is automatic. We did not understand what you typed. For questions about StoryTime, reply HELP. To Stop messages, reply STOP.")
# 	end

end


