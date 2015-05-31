ENV['RACK_ENV'] = "test"

require_relative "./spec_helper"

require '../app.rb'

# require '../models/user'

require 'capybara/rspec'
require 'rack/test'



configure :test do
  puts "yup"
end


configure :test do
   db = URI.parse('postgres://postgres:sharlach1@localhost/test')


  #adding development REDIS config
  ENV["REDISTOGO_URL"] = "redis://redistogo:120075187f5e39ba84e429f311eb69a5@hammerjaw.redistogo.com:9787/"
   
    ActiveRecord::Base.establish_connection(
        :adapter => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
        :host     => db.host,
        :username => db.user,
        :password => db.password,
        :database => db.path[1..-1],
        :encoding => 'utf8'
    )
end


#CONSTANTS


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

  it "responds to HELP NOW" do
    get "/test/909/STORY/ATT"
    get "/test/909/" + HELP_URL
    expect(@@twiml).to eq(HELPSMS)
  end

  it "responds to 'help now' (non-sprint)" do
    get "/test/911/STORY/ATT"
    get "/test/911/help%20now"
    expect(@@twiml).to eq(HELPSMS)
  end

  it "responds to HELP NOW from sprint" do
    get "/test/912/STORY/" + SPRINT_QUERY_STRING
    get "/test/912/" + HELP_URL
    expect(@@twiml).to eq(HELP_SPRINT)
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


