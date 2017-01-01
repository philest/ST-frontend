# require 'spec_helper'
# require 'timecop'
# require 'active_support/time'
# require 'twilio-ruby'
# require 'pony'
# require_relative '../../../config/pony'


# module TwilioWrap
# 	class Cli
# 		@@client = Twilio::REST::Client.new ENV["TW_ACCOUNT_SID"], ENV["TW_AUTH_TOKEN"]
# 		def self.client
# 			@@client
# 		end
# 	end
# end

# require 'workers/enrollment_worker'
# include TwilioTextingHelpers

# describe DeleteEnrollmentQueueRowWorker do
# 	# setup the scenario
# 	before(:each) do
# 		Sidekiq::Worker.clear_all
# 		@parent 	= User.create 	 child_name:"Lil' Aub",  phone:"+13013328953"
# 		@qid  = @parent.enrollment_queue_id
# 		@pid 	= @parent.id
# 	end

# 	# it's pretty much impossible to test the emailing behavior here :(

# 	context 'when worker successfully deletes row' do
# 		it 'it kills itself' do
# 			Sidekiq::Testing.inline! do
# 				DeleteEnrollmentQueueRowWorker.perform_async(
# 					@qid,
# 					@pid)
# 			end
# 			expect(DeleteEnrollmentQueueRowWorker.jobs.size).to eq 0
# 		end

# 		it 'deletes row' do
# 			expect {
# 				Sidekiq::Testing.inline! do
# 					DeleteEnrollmentQueueRowWorker.perform_async(@qid, @pid)
# 				end
# 			}.to change{EnrollmentQueue.where(id:@parent.enrollment_queue_id).first}.to nil
# 		end
# 	end
# end


# describe EnrollTextWorker, enroll_text_worker:true do


# 	# webmock stub template
# 	let (:stub) {			
# 		lambda do |to_phone, rest_verb, response, status| 
#  			stub_request(
#  				rest_verb, 
#  				"https://api.twilio.com/2010-04-01/Accounts/#{ENV['TW_ACCOUNT_SID']}/Messages.json"
#  				).
# 			with(
# 					:body => {
# 						"Body"=>"Hi, this is Mx. McEsterWahl. I'll be texting Lil' Aub books with StoryTime!\n\nYou can start early if you have Facebook Messenger. Tap here and enter 'go':\njoinstorytime.com/go",
# 						"From"=>"+12032023505", 
# 						"To"=>to_phone},
# 			    :headers => {
# 			    	'Accept'=>'application/json', 
# 			    	'Accept-Charset'=>'utf-8', 
# 			    	'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 
# 			    	'Authorization'=>'Basic QUNlYTE3ZTBiYmEzMDY2MDc3MGY2MmIxZTI4ZTEyNjk0NDo3MTZlMDU0N2JiZDgyYzE3OWI5YWFlOGViZmVmMGU5NQ==', 
# 			    	'Content-Type'=>'application/x-www-form-urlencoded', 
# 			    	'User-Agent'=>"twilio-ruby/4.3.0 (#{ENV['MACHINE']})"
# 			    }).
#       to_return(:status => status, :body => response, :headers => {})		
#     end
# 	}

# 	let (:media_stub) {			
# 		lambda do |to_phone, rest_verb, response, status| 
#  			stub_request(
#  				rest_verb, 
#  				"https://api.twilio.com/2010-04-01/Accounts/#{ENV['TW_ACCOUNT_SID']}/Messages.json"
#  				).
# 			with(
# 					:body => {
# 						"MediaUrl"=>"http://d2p8iyobf0557z.cloudfront.net/day1/twilio-mms-final.jpg",
# 						"From"=>"+12032023505", 
# 						"To"=>to_phone},
# 			    :headers => {
# 			    	'Accept'=>'application/json', 
# 			    	'Accept-Charset'=>'utf-8', 
# 			    	'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 
# 			    	'Authorization'=>'Basic QUNlYTE3ZTBiYmEzMDY2MDc3MGY2MmIxZTI4ZTEyNjk0NDo3MTZlMDU0N2JiZDgyYzE3OWI5YWFlOGViZmVmMGU5NQ==', 
# 			    	'Content-Type'=>'application/x-www-form-urlencoded', 
# 			    	'User-Agent'=>"twilio-ruby/4.3.0 (#{ENV['MACHINE']})"
# 			    }).
#       		to_return(:status => status, :body => response, :headers => {})		
#     	end
# 	}



# 	# setup the scenario
# 	before(:each) do
# 		Sidekiq::Worker.clear_all

# 		@teach 	 	= Teacher.create signature:"Mx. McEsterWahl", email:"poop@pee.com"
# 		@parent 	= User.create 	 child_name:"Lil' Aub",  phone:"+13013328953"
# 		@teach.add_user(@parent)

# 		body = "{\"caller_name\": null, \"country_code\": \"US\", \"phone_number\": \"+13013328953\", \"national_format\": \"(301) 332-8953\", \"carrier\": {\"mobile_country_code\": \"310\", \"mobile_network_code\": null, \"name\": \"Republic Wireless\", \"type\": \"mobile\", \"error_code\": null}, \"add_ons\": null, \"url\": \"https://lookups.twilio.com/v1/PhoneNumbers/+13013328953?Type=carrier\"}"

# 		body2 = "{\"caller_name\": null, \"country_code\": \"US\", \"phone_number\": \"5617893548\", \"national_format\": \"(561) 789-3548\", \"carrier\": {\"mobile_country_code\": \"310\", \"mobile_network_code\": null, \"name\": \"Republic Wireless\", \"type\": \"mobile\", \"error_code\": null}, \"add_ons\": null, \"url\": \"https://lookups.twilio.com/v1/PhoneNumbers/5617893548?Type=carrier\"}"		
# 		stub_request(:get, "https://lookups.twilio.com/v1/PhoneNumbers/5617893548?Type=carrier").
# 	     with(:headers => {'Accept'=>'application/json', 'Accept-Charset'=>'utf-8', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'Basic QUNlYTE3ZTBiYmEzMDY2MDc3MGY2MmIxZTI4ZTEyNjk0NDo3MTZlMDU0N2JiZDgyYzE3OWI5YWFlOGViZmVmMGU5NQ==', 'User-Agent'=>"twilio-ruby/4.3.0 (#{ENV['MACHINE']})"}).
# 	     to_return(:status => 200, :body => body2, :headers => {})

# 	   	stub_request(:get, "https://lookups.twilio.com/v1/PhoneNumbers/+13013328953?Type=carrier").
# 	     with(:headers => {'Accept'=>'application/json', 'Accept-Charset'=>'utf-8', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'Basic QUNlYTE3ZTBiYmEzMDY2MDc3MGY2MmIxZTI4ZTEyNjk0NDo3MTZlMDU0N2JiZDgyYzE3OWI5YWFlOGViZmVmMGU5NQ==', 'User-Agent'=>"twilio-ruby/4.3.0 (#{ENV['MACHINE']})"}).
# 	     to_return(:status => 200, :body => body, :headers => {})

# 		# EnrollTextWorker.any_instance.stub(:get_carrier).and_return("Republic Wireless")
# 	end


# 	# do a test where one fails, two succeed
# 	context 'when some jobs succeed but others dont' do
# 	end

# 	context 'when sequel throws an error' do
# 		before(:example) do
# 			success = "{\"sid\":\"MM0f1a7aeb7a644aaa851cd4cea5b5c8d5\",\"date_created\":\"Wed, 29 Jun 2016 16:56:55 +0000\",\"date_updated\":\"Wed, 29 Jun 2016 16:56:55 +0000\",\"date_sent\":null,\"account_sid\":\"ACea17e0bba30660770f62b1e28e126944\",\"to\":\"+13013328953\",\"from\":\"+12032023505\",\"messaging_service_sid\":null,\"body\":\"Hi, this is Mx. McEsterWahl. I'm sending you and Lil' Aub free books byFacebook Messenger\\n\\nTap here for your story!\\njoinstorytime.com/books\",\"status\":\"queued\",\"num_segments\":\"1\",\"num_media\":\"1\",\"direction\":\"outbound-api\",\"api_version\":\"2010-04-01\",\"price\":null,\"price_unit\":\"USD\",\"error_code\":null,\"error_message\":null,\"uri\":\"/2010-04-01/Accounts/ACea17e0bba30660770f62b1e28e126944/Messages/MM0f1a7aeb7a644aaa851cd4cea5b5c8d5.json\",\"subresource_uris\":{\"media\":\"/2010-04-01/Accounts/ACea17e0bba30660770f62b1e28e126944/Messages/MM0f1a7aeb7a644aaa851cd4cea5b5c8d5/Media.json\"}}"	
# 		    stub.call('+13013328953', :post, success, 	  200)

# 		    media_stub.call('+13013328953', :post, success, 	  200)

#     	end	

# 	    before(:each) do
# 	    	q_id = @parent.enrollment_queue.id
# 	    	phone= @parent.phone
# 	    	sig  = @parent.teacher.signature
# 	    	child= @parent.child_name
# 	    	@parent.destroy
# 	    	@num_jobs = 5
# 	    	@num_jobs.times do |x|
# 	    		Sidekiq::Testing.inline! do
# 	    			EnrollTextWorker.perform_async(q_id, phone, sig, nil, child)
# 	    	end
# 	    end
#     end
#     it 'adds jobs to DeleteEnrollmentQueueRowWorker queue' do

#     	expect(DeleteEnrollmentQueueRowWorker.jobs.size).to eq @num_jobs
#     end

#      it 'EnrollTextWorker kills all jobs' do
#     	expect(EnrollTextWorker.jobs.size).to eq 0
#     end

# 	end


# 	# by 'goes ok' I mean that no except was raised by Twilio library
# 	context 'everything goes ok' do
# 		before(:example) do
# 			# WebMock.allow_net_connect!
# 			# got these responses by doing HTTParty.post('url', options).to_json
# 			@blacklisted = "{\"code\":21610,\"message\":\"The message From/To pair violates a blacklist rule.\",\"more_info\":\"https://www.twilio.com/docs/errors/21610\",\"status\":400}"
# 			@success = "{\"sid\":\"MM0f1a7aeb7a644aaa851cd4cea5b5c8d5\",\"date_created\":\"Wed, 29 Jun 2016 16:56:55 +0000\",\"date_updated\":\"Wed, 29 Jun 2016 16:56:55 +0000\",\"date_sent\":null,\"account_sid\":\"ACea17e0bba30660770f62b1e28e126944\",\"to\":\"+13013328953\",\"from\":\"+12032023505\",\"messaging_service_sid\":null,\"body\":\"Hi, this is Mx. McEsterWahl. I'm sending you and Lil' Aub free books byFacebook Messenger\\n\\nTap here for your story!\\njoinstorytime.com/books\",\"status\":\"queued\",\"num_segments\":\"1\",\"num_media\":\"1\",\"direction\":\"outbound-api\",\"api_version\":\"2010-04-01\",\"price\":null,\"price_unit\":\"USD\",\"error_code\":null,\"error_message\":null,\"uri\":\"/2010-04-01/Accounts/ACea17e0bba30660770f62b1e28e126944/Messages/MM0f1a7aeb7a644aaa851cd4cea5b5c8d5.json\",\"subresource_uris\":{\"media\":\"/2010-04-01/Accounts/ACea17e0bba30660770f62b1e28e126944/Messages/MM0f1a7aeb7a644aaa851cd4cea5b5c8d5/Media.json\"}}"	

# 			# make the webmock stubs
# 		    stub.call('+13013328953', :post, @success, 	  200)
# 		    stub.call('5617893548', 	:post, @blacklisted, 400)
# 		    media_stub.call('+13013328953', :post, @success, 	  200)
# 		    media_stub.call('5617893548', 	:post, @blacklisted, 400)
# 	    end

# 	    context "a SPRINT phone number" do 
# 	    	before :example do
# 	    		success1 = "{\"sid\":\"MM0f1a7aeb7a644aaa851cd4cea5b5c8d5\",\"date_created\":\"Wed, 29 Jun 2016 16:56:55 +0000\",\"date_updated\":\"Wed, 29 Jun 2016 16:56:55 +0000\",\"date_sent\":null,\"account_sid\":\"ACea17e0bba30660770f62b1e28e126944\",\"to\":\"+15612125831\",\"from\":\"+12032023505\",\"messaging_service_sid\":null,\"body\":\"Hi, this is Mx. McEsterWahl. I'm sending you and Lil' Aub free books byFacebook Messenger\\n\\nTap here for your story!\\njoinstorytime.com/books\",\"status\":\"queued\",\"num_segments\":\"1\",\"num_media\":\"1\",\"direction\":\"outbound-api\",\"api_version\":\"2010-04-01\",\"price\":null,\"price_unit\":\"USD\",\"error_code\":null,\"error_message\":null,\"uri\":\"/2010-04-01/Accounts/ACea17e0bba30660770f62b1e28e126944/Messages/MM0f1a7aeb7a644aaa851cd4cea5b5c8d5.json\",\"subresource_uris\":{\"media\":\"/2010-04-01/Accounts/ACea17e0bba30660770f62b1e28e126944/Messages/MM0f1a7aeb7a644aaa851cd4cea5b5c8d5/Media.json\"}}"	
# 	    		success2 = "{\"sid\":\"MM0f1a7aeb7a644aaa851cd4cea5b5c8d5\",\"date_created\":\"Wed, 29 Jun 2016 16:56:55 +0000\",\"date_updated\":\"Wed, 29 Jun 2016 16:56:55 +0000\",\"date_sent\":null,\"account_sid\":\"ACea17e0bba30660770f62b1e28e126944\",\"to\":\"+15612125831\",\"from\":\"+12032023505\",\"messaging_service_sid\":null,\"body\":\"Hi, this is Mx. McEsterWahl. I'm sending you and Lil' Aub free books byFacebook Messenger\\n\\nTap here for your story!\\njoinstorytime.com/books\",\"status\":\"queued\",\"num_segments\":\"1\",\"num_media\":\"1\",\"direction\":\"outbound-api\",\"api_version\":\"2010-04-01\",\"price\":null,\"price_unit\":\"USD\",\"error_code\":null,\"error_message\":null,\"uri\":\"/2010-04-01/Accounts/ACea17e0bba30660770f62b1e28e126944/Messages/MM0f1a7aeb7a644aaa851cd4cea5b5c8d5.json\",\"subresource_uris\":{\"media\":\"/2010-04-01/Accounts/ACea17e0bba30660770f62b1e28e126944/Messages/MM0f1a7aeb7a644aaa851cd4cea5b5c8d5/Media.json\"}}"	

# 				stub.call('+15612125831', :post, success1, 200)
# 	    		media_stub.call('+15612125831', :post, success2, 200)

# 	    		# failed stub....
# 	    		# body = "{\"caller_name\": null, \"country_code\": \"US\", \"phone_number\": \"+13013328953\", \"national_format\": \"(301) 332-8953\", \"carrier\": {\"mobile_country_code\": \"310\", \"mobile_network_code\": null, \"name\": \"Sprint Spectrum, L.P.\", \"type\": \"mobile\", \"error_code\": null}, \"add_ons\": null, \"url\": \"https://lookups.twilio.com/v1/PhoneNumbers/+13013328953?Type=carrier\"}"

# 			   	# stub_request(:get, "https://lookups.twilio.com/v1/PhoneNumbers/+13013328953?Type=carrier").
# 			    #  with(:headers => {'Accept'=>'application/json', 'Accept-Charset'=>'utf-8', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'Basic QUNlYTE3ZTBiYmEzMDY2MDc3MGY2MmIxZTI4ZTEyNjk0NDo3MTZlMDU0N2JiZDgyYzE3OWI5YWFlOGViZmVmMGU5NQ==', 'User-Agent'=>"twilio-ruby/4.3.0 (#{ENV['MACHINE']})"}).
# 			    #  to_return(:status => 200, :body => body, :headers => {})
# 	    	end

# 	    	it "sends two sms messages with sprint", sprint:true do

# 	    		enrollworker = EnrollTextWorker.new

# 				allow(enrollworker).to receive(:get_carrier).and_return("Sprint Spectrum, L.P.")

# 				# expect(enrollworker).to receive(:send_sms).twice

# 				teach 	 	= Teacher.create signature:"Mx. McEsterWahl", email:"mc@donald.com"
# 				parent 		= User.create 	 child_name:"Lil' Aub",  phone:"+15612125831"
# 				teach.add_user(parent)

# 				Sidekiq::Testing::fake! do
# 					expect {
# 						enrollworker.perform(
# 							parent.enrollment_queue.id,
# 							'+15612125831',
# 							parent.teacher.signature,
# 							parent.child_name
# 						)
# 					}.to change(MessageWorker.jobs, :size).by(2)
# 				end

# 			end
				
# 			# expect(EnrollTextWorker.jobs.size).to eq 0	
# 	    end

			
# 		context 'blacklist phone number', enroll_text_worker:false do # stop sending these bleeding emails...
# 			it 'rescues error when phone number is blacklisted' do
# 				expect {
# 					Sidekiq::Testing.inline! do
# 						EnrollTextWorker.perform_async(
# 							@parent.enrollment_queue.id,
# 							'5617893548',
# 							@parent.teacher.signature,
# 							nil,
# 							@parent.child_name)
# 					end
# 				}.to_not raise_error
# 			end

# 			it 'kills the worker' do
# 				Sidekiq::Testing.inline! do
# 					EnrollTextWorker.perform_async(
# 						@parent.enrollment_queue.id,
# 						'5617893548',
# 						@parent.teacher.signature,
# 						nil,
# 						@parent.child_name)
# 				end
# 				expect(EnrollTextWorker.jobs.size).to eq 0				
# 			end

# 			it 'removes that enrollment queue row from the database', nil:true do
# 				Sidekiq::Testing.inline! do
# 					EnrollTextWorker.perform_async(
# 						@parent.enrollment_queue.id,
# 						'5617893548',
# 						@parent.teacher.signature,
# 						nil,
# 						@parent.child_name)
# 				end
# 				expect(EnrollmentQueue.where(user_id: @parent.id).first).to be_nil
# 			end

# 			it 'emails phil' do # TODO pls

# 			end
# 		end


# 		it 'after text, deletes row from EnrollementQueue' do
# 			qid = @parent.enrollment_queue.id
# 			expect {
# 				Sidekiq::Testing.inline! do
# 					EnrollTextWorker.perform_async(
# 						@parent.enrollment_queue.id,
# 						@parent.phone,
# 						@parent.teacher.signature,
# 						nil,
# 						@parent.child_name)
# 				end
# 			}.to change{EnrollmentQueue.where(:id=>qid).first}.to nil	
# 		end
# 	end

# 	describe "TwilioHelpers" do
# 		describe "good_carrier?" do
# 			it "knows Sprint is a bad carrier" do
# 				expect(good_carrier?(SPRINT)).to be false
# 			end 

# 			it "knows ATT is a bad carrier" do
# 				expect(good_carrier?(ATT)).to be false
# 			end 

# 			it "knows Verizon is a good carrier" do 
# 				expect(good_carrier?("Verizon Wireless")).to be true
# 			end 
# 		end
# 	end

# 	describe "text-in" do 

# 			before(:example) do
# 				success = "{\"sid\":\"MM0f1a7aeb7a644aaa851cd4cea5b5c8d5\",\"date_created\":\"Wed, 29 Jun 2016 16:56:55 +0000\",\"date_updated\":\"Wed, 29 Jun 2016 16:56:55 +0000\",\"date_sent\":null,\"account_sid\":\"ACea17e0bba30660770f62b1e28e126944\",\"to\":\"+13013328953\",\"from\":\"+12032023505\",\"messaging_service_sid\":null,\"body\":\"Hi, this is Mx. McEsterWahl. I'm sending you and Lil' Aub free books byFacebook Messenger\\n\\nTap here for your story!\\njoinstorytime.com/books\",\"status\":\"queued\",\"num_segments\":\"1\",\"num_media\":\"1\",\"direction\":\"outbound-api\",\"api_version\":\"2010-04-01\",\"price\":null,\"price_unit\":\"USD\",\"error_code\":null,\"error_message\":null,\"uri\":\"/2010-04-01/Accounts/ACea17e0bba30660770f62b1e28e126944/Messages/MM0f1a7aeb7a644aaa851cd4cea5b5c8d5.json\",\"subresource_uris\":{\"media\":\"/2010-04-01/Accounts/ACea17e0bba30660770f62b1e28e126944/Messages/MM0f1a7aeb7a644aaa851cd4cea5b5c8d5/Media.json\"}}"	
# 			    stub.call('+13013328953', :post, success, 	  200)
# 			    media_stub.call('+13013328953', :post, success, 	  200)
# 	    	end	

# 	    context "when NOT text-in" do 
# 			it "sends seperate MMS, SMS" do
# 				# That means we don't need more than one message jobs. 
# 				Sidekiq::Testing.fake! do
# 					EnrollTextWorker.perform_async(
# 						@parent.enrollment_queue.id,
# 						@parent.phone,
# 						@parent.teacher.signature,
# 						nil,
# 						@parent.child_name)
# 				end
# 				EnrollTextWorker.drain
# 				expect(MessageWorker.jobs.size).to eq 1 
# 				# expect(MessageWorker.jobs.first["args"].last).to eq "MMS"
# 			end
# 		end

# 	    context "when text-in" do 
# 	    	before(:example) do
# 	    				# Joint SMS + MMS Stub!! 
# 				body = "{\"sid\": \"MM34d9bd740850416ba9f9b6d407797c5b\", \"date_created\": \"Thu, 21 Jul 2016 17:36:13 +0000\", \"date_updated\": \"Thu, 21 Jul 2016 17:36:13 +0000\", \"date_sent\": null, \"account_sid\": \"ACea17e0bba30660770f62b1e28e126944\", \"to\": \"+13013328953\", \"from\": \"+12032023505\", \"messaging_service_sid\": null, \"body\": \"Hi, this is Mx. McEsterWahl. I'll be texting Lil' Aub books with StoryTime!\\n\\nYou can start now if you have Facebook Messenger. Tap here and enter 'go':\\njoinstorytime.com/go\", \"status\": \"queued\", \"num_segments\": \"1\", \"num_media\": \"1\", \"direction\": \"outbound-api\", \"api_version\": \"2010-04-01\", \"price\": null, \"price_unit\": \"USD\", \"error_code\": null, \"error_message\": null, \"uri\": \"/2010-04-01/Accounts/ACea17e0bba30660770f62b1e28e126944/Messages/MM34d9bd740850416ba9f9b6d407797c5b.json\", \"subresource_uris\": {\"media\": \"/2010-04-01/Accounts/ACea17e0bba30660770f62b1e28e126944/Messages/MM34d9bd740850416ba9f9b6d407797c5b/Media.json\"}}"
# 		       stub_request(:post, "https://api.twilio.com/2010-04-01/Accounts/ACea17e0bba30660770f62b1e28e126944/Messages.json").
# 		         with(:body => {"Body"=>"Hi, this is Mx. McEsterWahl. I'll be texting Lil' Aub books with StoryTime!\n\nYou can start now if you have Facebook Messenger. Tap here and enter 'go':\njoinstorytime.com/go", "From"=>"+12032023505", "MediaUrl"=>"http://d2p8iyobf0557z.cloudfront.net/day1/twilio-mms-final.jpg", "To"=>"+13013328953"},
# 		              :headers => {'Accept'=>'application/json', 'Accept-Charset'=>'utf-8', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'Basic QUNlYTE3ZTBiYmEzMDY2MDc3MGY2MmIxZTI4ZTEyNjk0NDo3MTZlMDU0N2JiZDgyYzE3OWI5YWFlOGViZmVmMGU5NQ==', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'twilio-ruby/4.3.0 (ruby/x86_64-darwin14 2.2.3-p173)'}).
# 		         to_return(:status => 200, :body => body, :headers => {})

# 				# success = "{\"sid\":\"MM0f1a7aeb7a644aaa851cd4cea5b5c8d5\",\"date_created\":\"Wed, 29 Jun 2016 16:56:55 +0000\",\"date_updated\":\"Wed, 29 Jun 2016 16:56:55 +0000\",\"date_sent\":null,\"account_sid\":\"ACea17e0bba30660770f62b1e28e126944\",\"to\":\"+15612125831\",\"from\":\"+12032023505\",\"messaging_service_sid\":null,\"body\":\"Hi, this is Mx. McEsterWahl. I'm sending you and Lil' Aub free books byFacebook Messenger\\n\\nTap here for your story!\\njoinstorytime.com/books\",\"status\":\"queued\",\"num_segments\":\"1\",\"num_media\":\"1\",\"direction\":\"outbound-api\",\"api_version\":\"2010-04-01\",\"price\":null,\"price_unit\":\"USD\",\"error_code\":null,\"error_message\":null,\"uri\":\"/2010-04-01/Accounts/ACea17e0bba30660770f62b1e28e126944/Messages/MM0f1a7aeb7a644aaa851cd4cea5b5c8d5.json\",\"subresource_uris\":{\"media\":\"/2010-04-01/Accounts/ACea17e0bba30660770f62b1e28e126944/Messages/MM0f1a7aeb7a644aaa851cd4cea5b5c8d5/Media.json\"}}"	
# 			 #    stub.call('+15612125831', :post, success, 	  200)
# 			 #    stub.call('+15612125831', :post, success, 	  200)
# 			 #    media_stub.call('+15612125831', :post, success, 200)

# 		    end

# 			it "sends signle MMS-SMS" do
# 				# That means we don't any message jobs.
# 				Sidekiq::Testing.fake! do
# 					EnrollTextWorker.perform_async(
# 						@parent.enrollment_queue.id,
# 						@parent.phone,
# 						@parent.teacher.signature,
# 						nil,
# 						@parent.child_name,
# 						text_in=true)
# 				end
# 				EnrollTextWorker.drain
# 				expect(MessageWorker.jobs.size).to eq 1
# 				# expect(MessageWorker.jobs.first["args"].last).to eq "SMS"				
# 			end

# 		# 	context "when bad carrier" do 
# 		# 		it "sends seperate MMS and SMS" do
		
# 		# body = "{\"caller_name\": null, \"country _code\": \"US\", \"phone_number\": \"+15612125831\", \"national_format\": \"(301) 332-8953\", \"carrier\": {\"mobile_country_code\": \"310\", \"mobile_network_code\": null, \"name\": \"AT&T Wireless\", \"type\": \"mobile\", \"error_code\": null}, \"add_ons\": null, \"url\": \"https://lookups.twilio.com/v1/PhoneNumbers/+13013328953?Type=carrier\"}"

# 	 #   	stub_request(:get, "https://lookups.twilio.com/v1/PhoneNumbers/+15612125831?Type=carrier").
# 	 #     with(:headers => {'Accept'=>'application/json', 'Accept-Charset'=>'utf-8', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'Basic QUNlYTE3ZTBiYmEzMDY2MDc3MGY2MmIxZTI4ZTEyNjk0NDo3MTZlMDU0N2JiZDgyYzE3OWI5YWFlOGViZmVmMGU5NQ==', 'User-Agent'=>"twilio-ruby/4.3.0 (#{ENV['MACHINE']})"}).
# 	 #     to_return(:status => 200, :body => body, :headers => {})

# 		# 			# That means we don't any message jobs.
# 		# 			Sidekiq::Testing.fake! do
# 		# 				EnrollTextWorker.perform_async(
# 		# 					@parent.enrollment_queue.id,
# 		# 					"+15612125831", #ATT
# 		# 					@parent.teacher.signature,
# 		# 					@parent.child_name,
# 		# 					text_in=true)
# 		# 			end
# 		# 			EnrollTextWorker.drain
# 		# 			expect(MessageWorker.jobs.size).to eq 2 
# 		# 		end
# 		# 	end


# 		end



# 	end 



# end