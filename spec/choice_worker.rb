ENV['RACK_ENV'] = "test"

require_relative "./spec_helper"


require 'capybara/rspec'
require 'rack/test'

# require_relative '../config/environments'

require_relative '../messageSeries'




START_SMS_1 = "StoryTime: Welcome to StoryTime, free pre-k stories by text! You'll get "

START_SMS_2 = " stories/week-- the first is on the way!\n\nText " + HELP + " for help, or " + STOP + " to cancel."

SPRINT = "Sprint Spectrum, L.P."

describe 'The StoryTime Workers' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end


   describe "ChoiceWorker" do


		before(:each) do
  			TestChoiceWorker.jobs.clear
		end


   		it "properly enques a TestChoiceWorker job" do
   		expect {
   		# assert_equal 0, HardWorker.jobs.size
   				TestChoiceWorker.perform_async("+15612125831")
   				# assert_equal 1, HardWorker.jobs.size
   		}.to change(TestChoiceWorker.jobs, :size).by(1)
   		end

   		it "starts with none, then adds more one" do
   			expect(TestChoiceWorker.jobs.size).to eq(0)
   			TestChoiceWorker.perform_async("+15612125831")
   			expect(TestChoiceWorker.jobs.size).to eq(1)
   		end

		  # SMS TESTS
		it "isn't there before" do
	 	  expect(User.find_by_phone("555")).to eq(nil)
		end

		describe "choiceWorker Details" do

		before(:each) do
  			@user = User.create(phone: "666", awaiting_choice: true)
		end

		
			it "updates everything properly when make good choice" do
				get '/test/556/p/ATT'
				@user.reload
		 	 	expect(@user.series_choice).to eq("p")
		 	 	expect(@user.next_index_in_series).to eq(0)
		 	 	expect(@user.awaiting_choice).to eq(false)		 	 	
			end




		end






  end 

end


