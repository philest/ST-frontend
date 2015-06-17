ENV['RACK_ENV'] = "test"

require_relative "./spec_helper"


require 'capybara/rspec'
require 'rack/test'

# require_relative '../config/environments'

puts ENV["REDISTOGO_URL"] + "\n\n\n\n"




START_SMS_1 = "StoryTime: Welcome to StoryTime, free pre-k stories by text! You'll get "

START_SMS_2 = " stories/week-- the first is on the way!\n\nText " + HELP + " for help, or " + STOP + " to cancel."

SPRINT = "Sprint Spectrum, L.P."

describe 'The StoryTime Workers' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end


   describe "FirstTextWoker" do



   		it "properly enques a firstTextWorker" do
   		expect {
   				# assert_equal 0, HardWorker.jobs.size
   				TestFirstTextWorker.perform_async("+15612125831")
   				# assert_equal 1, HardWorker.jobs.size
   		}.to change(TestFirstTextWorker.jobs, :size).by(1)
   		end


		  # SMS TESTS
		it "isn't there before" do
	 	  expect(User.find_by_phone("555")).to eq(nil)
		end

		before(:each) do
  			get '/test/556/STORY/ATT'
		end

		it "has all the Brandon SMS in right order" do
			expect(@@twiml_sms).to eq([START_SMS_1 + START_SMS_2].push TestFirstTextWorker::FIRST_SMS)
		end



  end 

end


