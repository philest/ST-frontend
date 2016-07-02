#  spec/views/enroll_spec.rb       Phil Esterman    
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

  it "loads /signup" do 
      visit '/signup'
      expect(page).to have_content "get your class free stories"
  end 

  it "does not load a random page" do 
      visit '/signup'
      expect(page).to_not have_content "fake fake fake... / 
                                        just my analysis."
  end

  context "when properly enrolling a family", :type => :feature, :js => :true do
    
    before(:each) do
      visit '/signup'   
      select('Ms.', :from => 'teacher_prefix')
      fill_in('teacher_signature', :with => 'Stobierski')
      fill_in('teacher_email', :with => "sam_stobierski@ymca.org")
      fill_in('name_0', :with => 'Art Vandelay')
      fill_in('phone_0', :with => '5612125888')
    end

    it "doesn't give invalid phone errors" do
      expect(page).to_not have_content "Invalid"
    end

    it "does redirect" do
      click_button('Add people')
      expect(page).to have_content "Great!"
    end

  end 

  context "when entering invalid phone", :type => :feature, :js => :true do
    
    before(:each) do
      visit '/signup'   
      select('Ms.', :from => 'teacher_prefix')
      fill_in('teacher_signature', :with => 'Stobierski')
      fill_in('teacher_email', :with => "sam_stobierski@ymca.org")
      fill_in('name_0', :with => 'Art Vandelay')
      fill_in('phone_0', :with => '5612125')
      fill_in('name_1', :with => 'Phil Vandelay')
      fill_in('phone_0', :with => 'fakefake')

    end

    it "gives invalid phone errors" do
      fill_in('name_3', :with => 'Phil Vandelay')
      expect(page).to have_content "Invalid"
    end

  end 

  context "when submitting with no teacher name", :type => :feature, :js => :true do
    
    before(:each) do
      visit '/signup'   
      fill_in('teacher_email', :with => "sam_stobierski@ymca.org")
      fill_in('name_0', :with => 'Art Vandelay')
      fill_in('phone_0', :with => '5612125888')
      click_button('Add people')
    end

    it "shows error message" do
      expect(page).to have_content "Please correct"
    end

    it "does not redirect" do
      expect(page).to have_content "get your class free stories"
    end

  end 

  context "when submitting with no teacher email", :type => :feature, :js => :true do
    
    before(:each) do
      visit '/signup'   
      select('Ms.', :from => 'teacher_prefix')
      fill_in('teacher_signature', :with => 'Stobierski')
      fill_in('name_0', :with => 'Art Vandelay')
      fill_in('phone_0', :with => '5612125888')
      click_button('Add people')
    end

    it "shows error message" do
      expect(page).to have_content "Please correct"
    end

    it "does not redirect" do
      expect(page).to have_content "get your class free stories"
    end

  end 

  context "when submitting with an improper email", :type => :feature, :js => :true do
    
    before(:each) do
      visit '/signup'   
      select('Ms.', :from => 'teacher_prefix')
      fill_in('teacher_signature', :with => 'Stobierski')
      fill_in('teacher_email', :with => "sam_stobierski")
      fill_in('name_0', :with => 'Art Vandelay')
      fill_in('phone_0', :with => '5612125888')
      click_button('Add people')
    end

    it "shows error message" do
      expect(page).to have_content "Please enter a valid email"
    end

    it "does not redirect" do
      expect(page).to have_content "get your class free stories"
    end

  end 

  it "has the flyer" do
      get '/signup/flyer'
      expect(last_response).to be_ok
  end




end




