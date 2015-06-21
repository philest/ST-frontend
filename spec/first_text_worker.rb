ENV['RACK_ENV'] = "test"

require_relative "./spec_helper"

require 'capybara/rspec'
require 'rack/test'

require_relative '../helpers'


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


   describe "FirstTextWorker" do


		before(:each) do
  			FirstTextWorker.jobs.clear
  			Helpers.initialize_testing_vars
		end

   		it "properly enques a firstTextWorker" do
   		expect {
   		# assert_equal 0, HardWorker.jobs.size
   				FirstTextWorker.perform_async("+15612125831")
   				# assert_equal 1, HardWorker.jobs.size
   		}.to change(FirstTextWorker.jobs, :size).by(1)
   		end

   		it "starts with none, then adds more one" do
   			expect(FirstTextWorker.jobs.size).to eq(0)
   			FirstTextWorker.perform_async("+15612125831")
   			expect(FirstTextWorker.jobs.size).to eq(1)
   		end

		  # SMS TESTS
		it "isn't there before" do
	 	  expect(User.find_by_phone("555")).to eq(nil)
		end

		it "has all the first_text Brandon S-MS in right order" do
			get '/test/556/STORY/ATT'
			expect(FirstTextWorker.jobs.size).to eq(1)
			FirstTextWorker.drain
			expect(FirstTextWorker.jobs.size).to eq(0)
			expect(Helpers.getSMSarr).to eq([START_SMS_1 + "2" + START_SMS_2].push FirstTextWorker::FIRST_SMS)
		end

		it "has all the first_text Brandon M-ms in right order" do
			get '/test/556/STORY/ATT'
			expect(FirstTextWorker.jobs.size).to eq(1)
			FirstTextWorker.drain
			expect(FirstTextWorker.jobs.size).to eq(0)
			expect(Helpers.getMMSarr).to eq(FirstTextWorker::FIRST_MMS)
		end

		
		it "has all the SAMPLE S-MS in right order" do
			get '/test/556/SAMPLE/ATT'
			expect(FirstTextWorker.jobs.size).to eq(1)
			FirstTextWorker.drain
			expect(FirstTextWorker.jobs.size).to eq(0)
			expect(Helpers.getSMSarr).to eq([FirstTextWorker::SAMPLE_SMS])
		end		

		it "has all the SAMPLE M-MS in right order" do
			get '/test/556/SAMPLE/ATT'
			expect(FirstTextWorker.jobs.size).to eq(1)
			FirstTextWorker.drain
			expect(FirstTextWorker.jobs.size).to eq(0)
			expect(Helpers.getMMSarr).to eq(FirstTextWorker::FIRST_MMS)
		end		

		it "sends the example SMS well" do 
			get '/test/556/EXAMPLE/ATT'
			expect(FirstTextWorker.jobs.size).to eq(1)
			FirstTextWorker.drain
			expect(FirstTextWorker.jobs.size).to eq(0)
			expect(Helpers.getSMSarr).to eq([FirstTextWorker::EXAMPLE_SMS])
		end


		it "sends the example MMS well" do 
			get '/test/556/EXAMPLE/ATT'
			expect(FirstTextWorker.jobs.size).to eq(1)
			FirstTextWorker.drain
			expect(FirstTextWorker.jobs.size).to eq(0)
			expect(Helpers.getMMSarr).to eq(FirstTextWorker::FIRST_MMS)
		end


  end 

end


