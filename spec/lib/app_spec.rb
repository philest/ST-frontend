require 'spec_helper'
require 'app'
require 'timecop'
require 'active_support/time'
require 'workers'

# do the stuff here: http://recipes.sinatrarb.com/p/testing/rspec
describe Enroll do
	include Rack::Test::Methods
	include ScheduleHelpers
	include EmailSpec::Helpers
	include EmailSpec::Matchers

	before(:all) do
		@params = { 
			:name_0 => "Phil Esterman", :phone_0 => "5612125831",
			:name_1 => "David McPeek", :phone_1 => "8186897323",
			:name_2 => "Aubrey Wahl", :phone_2 => "3013328953",
			:teacher_signature => "McEsterWahl", :teacher_email => "david.mcpeek@yale.edu",
	 	}
	end


	def app
		Enroll
	end

	
	context "reply to simple message from parent" do
		before(:example) do
			xml_res = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><Response><Message>StoryTime: Hi, we'll send your text to your teacher. They'll see it next time they are on their computer.</Message></Response>"
			stub_request(:get, "http://st-enroll.herokuapp.com/sms?ToCountry=US&ToState=CT&SmsMessageSid=SM9db3ba75674a22a108695578bcd8d3b5&NumMedia=0&ToCity=DARIEN&FromZip=90066&SmsSid=SM9db3ba75674a22a108695578bcd8d3b5&FromState=CA&SmsStatus=received&FromCity=LOS+ANGELES&Body=Hi+there&FromCountry=US&To=%2B12032023505&ToZip=06820&NumSegments=1&MessageSid=SM9db3ba75674a22a108695578bcd8d3b5&AccountSid=ACea17e0bba30660770f62b1e28e126944&From=%2B18186897323&ApiVersion=2010-04-01")
			.to_return(
					status: 200,
					body: xml_res,
					headers: { 'Content-Type' => 'text/html' }
				)
	    end

	end

end