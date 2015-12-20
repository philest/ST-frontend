ENV['RACK_ENV'] = "test"

require_relative "./spec_helper"

require 'capybara/rspec'
require 'rack/test'

require_relative '../helpers'
require_relative '../constants'
require_relative '../app/app'

# require_relative '../config/environments'

puts ENV["REDISTOGO_URL"] + "\n\n\n\n"

SPRINT = "Sprint Spectrum, L.P."
 
Sidekiq::Testing.inline!


include Text

describe 'First Text Message' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end



		before(:each) do
  			FirstTextWorker.jobs.clear
  			Helpers.initialize_testing_vars
  			NextMessageWorker.jobs.clear
  			Sidekiq::Testing.inline!
		end


		  # SMS TESTS
		it "isn't there before" do
	 	  expect(User.find_by_phone("555")).to eq(nil)
		end

		
		it "has all the SAMPLE S-MS in right order" do
			get '/test/556/SAMPLE/ATT'
			expect(NextMessageWorker.jobs.size).to eq(0)
			expect(Helpers.getSMSarr).to eq([Text::SAMPLE_SMS])
			puts Text::SAMPLE_SMS
		end		

		it "registers SAMPLE with whitespace" do
			get '/test/556/%20SAMPLE%20%0A/ATT'
			expect(NextMessageWorker.jobs.size).to eq(0)
			expect(Helpers.getSMSarr).to eq([Text::SAMPLE_SMS])
			puts Text::SAMPLE_SMS
		end		

		it "sends Sprint-Sample to sprint phones" do
			get '/test/556/%20SAMPLE%20%0A/'+Text::SPRINT_QUERY_STRING
			expect(NextMessageWorker.jobs.size).to eq(0)
			expect(Helpers.getSMSarr).to eq([Text::SAMPLE_SPRINT_SMS])
			puts Text::SAMPLE_SPRINT_SMS
		end

		it "sends the example with whitespace well" do 
			get '/test/556/%20%0AEXAMPLE%20%0A/ATT'
			expect(NextMessageWorker.jobs.size).to eq(0)
			expect(Helpers.getSMSarr).to eq([Text::EXAMPLE_SMS])
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


