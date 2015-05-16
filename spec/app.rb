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
end

