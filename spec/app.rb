ENV['RACK_ENV'] = 'test'

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
  	  expect(User.find_by_phone("555").phone).not_to eq("555")
  end

  it "signs up" do
  	get '/test/555/STORY'
  	expect(User.find_by_phone("555").phone).to eq("555")
  end

  it "signs up different numbers" do
  	get '/test/888/STORY'
  	expect(User.find_by_phone("888").phone).to eq("888")
  end

  describe User do
  	before(:each) do
 	 	@user = User.create(child_name: EMPTY_STR, child_age: EMPTY_INT, time: EMPTY_STR, phone: "444")
  	end

  	it "has empty child age value" do
  		expect(@user.child_age).to_eq(EMPTY_INT)
  	end



  end



end

