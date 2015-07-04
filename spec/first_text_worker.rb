ENV['RACK_ENV'] = "test"

require_relative "./spec_helper"

require 'capybara/rspec'
require 'rack/test'

require_relative '../helpers'
require_relative '../constants'


# require_relative '../config/environments'

puts ENV["REDISTOGO_URL"] + "\n\n\n\n"

SPRINT = "Sprint Spectrum, L.P."


include Text

describe 'The StoryTime Workers' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end


   describe "First Text Message" do


		before(:each) do
  			FirstTextWorker.jobs.clear
  			Helpers.initialize_testing_vars
  			NextMessageWorker.jobs.clear
		end

   		it "properly enques a Text" do
   		expect {
   		# assert_equal 0, HardWorker.jobs.size
   				NextMessageWorker.perform_async("SMS", ["a", "b"], "+15612125831")
   				# assert_equal 1, HardWorker.jobs.size
   		}.to change(NextMessageWorker.jobs, :size).by(1)
   		end

   		it "starts with none, then adds more one" do
   			expect(NextMessageWorker.jobs.size).to eq(0)
   			NextMessageWorker.perform_async("+15612125831")
   			expect(NextMessageWorker.jobs.size).to eq(1)
   		end

		  # SMS TESTS
		it "isn't there before" do
	 	  expect(User.find_by_phone("555")).to eq(nil)
		end

		it "has all the first_text Brandon S-MS in right order" do
			get '/test/556/STORY/ATT'
			expect(Helpers.getSMSarr).to eq([Text::START_SMS_1 + "2" + Text::START_SMS_2])
		end

		it "has all the first_text Brandon M-ms in right order" do
			get '/test/556/STORY/ATT'
			expect(NextMessageWorker.jobs.size).to eq(0)
			expect(Helpers.getMMSarr).to eq(Text::FIRST_MMS)
		end

		
		it "has all the SAMPLE S-MS in right order" do
			get '/test/556/SAMPLE/ATT'
			expect(NextMessageWorker.jobs.size).to eq(0)
			expect(Helpers.getSMSarr).to eq([Text::SAMPLE_SMS])
			puts Text::SAMPLE_SMS
		end		

		it "has all the SAMPLE M-MS in right order" do
			get '/test/556/SAMPLE/ATT'
			expect(NextMessageWorker.jobs.size).to eq(0)
			expect(Helpers.getMMSarr).to eq(Text::FIRST_MMS)
		end		

		it "sends the example SMS well" do 
			get '/test/556/EXAMPLE/ATT'
			expect(NextMessageWorker.jobs.size).to eq(0)
			expect(Helpers.getSMSarr).to eq([Text::EXAMPLE_SMS])
		end


		it "sends the sample MMS well" do 
			get '/test/556/SAMPLE/ATT'
			expect(NextMessageWorker.jobs.size).to eq(0)
			expect(Helpers.getSMSarr).to eq([Text::SAMPLE_SMS])
		end

		it "properly updates total_messages" do 
			get '/test/556/STORY/ATT'
			@user = User.find_by(phone: "556")
			@user.reload 

			expect(NextMessageWorker.jobs.size).to eq(0)
			@user.reload

			expect(@user.total_messages).to eq(1)
		end




  end 

end


