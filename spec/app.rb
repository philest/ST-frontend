
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

# STAGE 2 TESTS 
  it "registers numeric age" do
  	get '/test/111/STORY'
  	get '/test/111/3'
  	expect(@@twiml).to eq("StoryTime: Great! You've got free nightly stories. Reply with your child's name and your preferred time to receive stories (e.g. Brianna 5:30pm)")
  end

  it "registers age in words" do
  	get '/test/222/STORY'
  	get '/test/222/three'
  	expect(@@twiml).to eq("StoryTime: Great! You've got free nightly stories. Reply with your child's name and your preferred time to receive stories (e.g. Brianna 5:30pm)")
  end

  it "rejects non-age" do
  	get '/test/1000/STORY'
  	get '/test/1000/badphone'
  	expect(@@twiml).to eq("We did not understand what you typed. Please reply with your child's age in years. For questions about StoryTime, reply HELP. To Stop messages, reply STOP.")
  end

# STAGE 3 TESTS
	it "registers name then time" do
		get '/test/833/STORY'
		get '/test/833/3'
		get "/test/833/Lindsay%206:00pm"
		expect(@@twiml).to eq("StoryTime: Sounds good! We'll send you and Lindsay a new story each night at 6:00pm.")
	end

	it "rejects a bad registration" do
		get '/test/633/STORY'
		get '/test/633/3'
		get '/test/633/Lindsay'
		expect(@@twiml).to eq("(1/2)We did not understand what you typed. Reply with your child's name and your preferred time to receive stories (e.g. Brianna 5:30pm).")	
	end


# PASSED ALL STAGES TESTS
	it "doesn't recognize further commands" do
		get '/test/488/STORY'
		get '/test/488/3'
		get "/test/488/Lindsay%206:00pm"
		get "/test/488/hello"
		expect(@@twiml).to eq("This service is automatic. We did not understand what you typed. For questions about StoryTime, reply HELP. To Stop messages, reply STOP.")
	end

end

