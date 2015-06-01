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



describe 'The StoryTime App' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
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
  	expect(@@twiml).to eq(STARTSMS)
  end

  it "sends correct sign up sms to Sprint users" do
    get '/test/998/STORY/' + SPRINT_QUERY_STRING
    expect(@@twiml).to eq(START_SPRINT)
  end

  describe "User" do

  	before(:each) do
 	 	  @user = User.create(child_name: EMPTY_STR, child_birthdate: EMPTY_STR, phone: "444")
  	end

      	it "has empty child birthdate value" do
      		expect(@user.child_birthdate).to eq(EMPTY_STR)
      	end

        it "has proper default age of 4" do
           expect(@user.child_age).to eq(4)
        end

        it "has proper default time of 5:00pm" do
           expect(@user.time).to eq("5:00pm")
        end

  end 


#HELP TESTS
  describe "Help tests" do
    before(:each) do
      @user = User.create(phone: "400")
    end


    it "responds to HELP NOW" do
      get "/test/400/" + HELP_URL + "/ATT"
      expect(@@twiml).to eq(HELPSMS)
    end

    it "responds to 'help now' (non-sprint)" do
      get "/test/400/help%20now/ATT"
      expect(@@twiml).to eq(HELPSMS)
    end


    describe "sub test" do
      before(:each) do
        @user.update(carrier: "Sprint Spectrum, L.P.")
      end

        it "responds to HELP NOW from sprint" do
          get "/test/400/HELP%20NOW/" + SPRINT_QUERY_STRING
          expect(@@twiml).to eq(HELP_SPRINT)
      end

    end

  end


#BIRTHDAY REGISTRATION
  describe "BIRTHDATE tests" do
    before(:each) do
      @user = User.create(phone: "500", story_number: 4) #have just received third story
    end


    it "should not register invalid birthdate" do
      # binding.pry
      get '/test/500/0912555/ATT'
      expect(@@twiml).to eq(WRONG_BDAY_FORMAT)
    end

    it "registers a custom birthdate" do
      get '/test/500/0911/ATT'
     TIME_SMS = "StoryTime: Great! Your child's birthdate is " + "09" + "/" + "11" + ". If not correct, reply STORY. If correct, enjoy your next age-appropriate story!"
      expect(@@twiml).to eq(TIME_SMS)
    end

    it "correctly updates age" do
      get '/test/500/0911/ATT'
      @user.reload
      expect(@user.child_age).to eq(3)
    end



    it "too young shouldn't be allowed in" do
       get '/test/500/0914/ATT'
      expect(@@twiml).to eq(TOO_YOUNG_SMS)
    end


    it "keeps birthdate for too young" do
       get '/test/500/0914/ATT'
       @user.reload
      expect(@user.child_birthdate).to eq("0914")
    end



    describe "further Bday" do
      before(:each) do
      @user.update(story_number: 2) #have just received third story
    end

      it "shouldn't register a birthday until third story" do
        get '/test/500/0911/ATT'
       TIME_SMS = "StoryTime: Great! Your child's birthdate is " + "09" + "/" + "11" + ". If not correct, reply STORY. If correct, enjoy your next age-appropriate story!"
        expect(@@twiml).not_to eq(TIME_SMS)
      end

    end

  end


    describe "TIME tests" do
    before(:each) do
      @user = User.create(phone: "600", story_number: 2) #have just received first two stories
    end

      it "registers a custom time" do
        get '/test/600/6:00pm/ATT'
        @user.reload
        expect(@@twiml).to eq("StoryTime: Sounds good! Your new story time is #{@user.time}-- enjoy!")
      end

      it "registers a custom time in spaced format" do
        get '/test/600/6:00%20pm/ATT'
        @user.reload
        expect(@@twiml).to eq("StoryTime: Sounds good! Your new story time is #{@user.time}-- enjoy!")
      end

      describe "further time tests" do
        before(:each) do
        @user.update(story_number: 1) #have just received third story
      end

      it "shouldn't register a time until second story" do
        get '/test/600/6:00pm/ATT'
        expect(@@twiml).to eq(NO_OPTION)
      end

    end



    describe "feedback" do
      before(:each) do
        @user = User.create(phone: "700", story_number: 1)
      end

    it "updates last_feedback" do
      get '/test/700/5/ATT'
      @user.reload
      expect(@user.last_feedback).to eq(0)
    end

    it "updates last_feedback on conflict days" do
      @user.update(story_number: 4)
      @user.reload
      get '/test/700/5/ATT'
      @user.reload
      expect(@user.last_feedback).to eq(3)
    end

    it "delivers right tip (first day) for sprint" do
          get '/test/700/5/' + SPRINT_QUERY_STRING
          @user.reload
          expect(@@twiml).to eq(@@tips_sprint[0])
    end

   it "delivers right tip (first day) for normal" do
          get '/test/700/5/ATT'
          @user.reload
          expect(@@twiml).to eq(@@tips_normal[0])
    end

       it "delivers right tip (second day) for normal" do
          @user.update(story_number: 2)
          @user.reload         
          get '/test/700/5/ATT'
          @user.reload
          expect(@@twiml).to eq(@@tips_normal[1])
    end


  end




      describe "STOP NOW works" do
        before(:each) do
          @user = User.create(phone: "800", story_number: 1, subscribed: true)
        end

        it "properly unsubscribes" do
          get '/test/800/' + STOP_URL + "/ATT"
          @user.reload
          expect(@user.subscribed).to eq(false)
        end


        it "properly resubscribes" do
          get '/test/800/' + STOP_URL + "/ATT"
          @user.reload
          get '/test/800/STORY/ATT'
          @user.reload
          expect(@user.subscribed).to eq(true)
        end

        it "send good resubscription msg" do
          get '/test/800/' + STOP_URL + "/ATT"
          @user.reload
          get '/test/800/STORY/ATT'
          @user.reload
          expect(@@twiml).to eq(RESUBSCRIBE)
        end


      end





end







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


