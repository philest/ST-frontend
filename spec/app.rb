
require 'spec_helper'
require './app.rb'
require 'rspec'
require 'capybara/rspec'
require 'rack/test'


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
  	get '/test/555/STORY'
  	expect(User.find_by_phone("555").phone).to eq("555")
  end

  it "signs up different numbers" do
  	get '/test/888/STORY'
  	expect(User.find_by_phone("888").phone).to eq("888")
  end

  it "sends correct sign up sms" do
  	get '/test/999/STORY'
  	expect(@@twiml).to eq("StoryTime: Thanks for signing up! Reply with your child's age in years (e.g. 3).")
  end


  describe User do
  	before(:each) do
 	 	@user = User.create(child_name: EMPTY_STR, child_age: EMPTY_INT, time: EMPTY_STR, phone: "444")
  	end

  	it "has empty child age value" do
  		expect(@user.child_age).to eq(EMPTY_INT)
  	end

  end

#HELP TESTS

  it "responds to HELP (non-sprint)" do
    get "/test/909/STORY"
    get "/test/909/HELP"
    expect(@@twiml).to eq("StoryTime sends 2 msgs/week. If msgs aren't delivered properly or you have feedback, please call or text our director, Phil, at 561-212-5831.
Remember that looking at screens within two hours of bedtime can delay children's sleep and carry health risks, so read StoryTime before 6pm. 
Reply STOP to cancel messages.")
  end

  it "responds to \'help\' (non-sprint)" do
    get "/test/911/STORY"
    get "test/911/help"
    expect(@@twiml).to eq("StoryTime sends 2 msgs/week. If msgs aren't delivered properly or you have feedback, please call or text our director, Phil, at 561-212-5831.
Remember that looking at screens within two hours of bedtime can delay children's sleep and carry health risks, so read StoryTime before 6pm. 
Reply STOP to cancel messages.")
  end

  it "responds to HELP in-midst signup" do
    get "/test/912/STORY"
    get "test/912/091412"
    get "test/912/help"
    expect(@@twiml).to eq("StoryTime sends 2 msgs/week. If msgs aren't delivered properly or you have feedback, please call or text our director, Phil, at 561-212-5831.
Remember that looking at screens within two hours of bedtime can delay children's sleep and carry health risks, so read StoryTime before 6pm. 
Reply STOP to cancel messages.")
  end


# STAGE 2 TESTS 
  it "registers numeric age" do
  	get '/test/111/STORY'
  	get '/test/111/091412'
  	expect(@@twiml).to eq("StoryTime: Great! You've got free nightly stories. Reply with your preferred time to receive stories (e.g. 6:30pm)")
  end

  it "registers age in words" do
  	get '/test/222/STORY'
  	get '/test/222/011811'
  	expect(@@twiml).to eq("StoryTime: Great! You've got free nightly stories. Reply with your preferred time to receive stories (e.g. 6:30pm)")
  end

  it "rejects non-age" do
  	get '/test/1000/STORY'
  	get '/test/1000/badphone'
  	expect(@@twiml).to eq("We did not understand what you typed. Please reply with your child's birthdate in MMDDYY format. For questions about StoryTime, reply HELP. To Stop messages, reply STOP.")
  end

# STAGE 3 TESTS
	it "registers timepm" do
		get '/test/833/STORY'
		get '/test/833/091412'
		get "/test/833/6:00pm"
		expect(@@twiml).to eq("StoryTime: Sounds good! We'll send you and your child a new story each night at 6:00pm.")
	end


  it "registers time then pm" do
    get '/test/844/STORY'
    get '/test/844/091412'
    get '/test/844/6:00%20pm'
    expect(@@twiml).to eq("StoryTime: Sounds good! We'll send you and your child a new story each night at 6:00pm.")
  end


	it "rejects a bad time registration" do
		get '/test/633/STORY'
		get '/test/633/091412'
		get '/test/633/boo'
		expect(@@twiml).to eq("(1/2)We did not understand what you typed. Reply with your child's preferred time to receive stories (e.g. 6:30pm).")	
	end


# PASSED ALL STAGES TESTS
	it "doesn't recognize further commands" do
		get '/test/488/STORY'
		get '/test/488/091412'
		get '/test/488/6:00pm'
		get '/test/488/hello'
		expect(@@twiml).to eq("This service is automatic. We did not understand what you typed. For questions about StoryTime, reply HELP. To Stop messages, reply STOP.")
	end

end

