#  spec/views/enroll.rb       Phil Esterman    
# 
#  Testing the Teacher Enrollment interface. 
#  --------------------------------------------------------

# set test enviroment
ENV['RACK_ENV'] = "test"

# DEPENDENCIES 
require_relative "../spec_helper"

require 'capybara/rspec'
require 'capybara/dsl'
require 'rack/test'
require 'timecop'

require_relative '../../app/app.rb'



Capybara.app = Sinatra::Application



describe 'Teacher Enrollment Interface', :type => :feature, :js => :true do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
  

  it "loads homepage" do 
      visit '/'
      expect(page).to have_content "free"
  end

  it "loads /enroll" do 
      visit '/enroll'
      expect(page).to have_content "get your class free stories"
  end 

  it "does not load a random page" do 
      visit '/enroll'
      expect(page).to_not have_content "fake fake fake... / 
                                        just my analysis."
  end 


end




