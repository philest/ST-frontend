require 'spec_helper'
# require 'app'
require 'timecop'
require 'active_support/time'
require 'workers'
require_relative '../../app/app'
require 'rack/test'
# require 'test/unit'

describe 'invite modal' do
	include Rack::Test::Methods

	ENV['RACK_ENV'] = 'test'

	def app
		App
	end

	it 'returns 200 http code' do
		get '/'
		puts last_response.body
		expect(last_response).to be_ok
		# expect(response.response_code).to eq 200
	end
end

