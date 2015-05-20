
require 'spec_helper'
require './workers/some_worker'
require 'rspec'
require 'capybara/rspec'
require 'rack/test'


describe 'SomeWorker' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end


  it "knows which user gets story next" do
  	User.create(name: "Bob", time: "5:30pm", phone: "898")
  	User.create(name: "Loria", time: "6:30pm", phone: "798")
  	User.create(name: "Jessica", time: "6:30am", phone: "698")

  	@user = User.find_by_name("Bob")

  	SomeWorker.sendStory?(@user, "12:30pm")


  end



end