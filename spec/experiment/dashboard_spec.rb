#  spec/experiment/dashboard_spec.rb       Phil Esterman    
# 
#  Testing the Create Experiment dashboard. 
#  --------------------------------------------------------

# set test enviroment
ENV['RACK_ENV'] = "test"


# DEPENDENCIES 
require_relative "../spec_helper"

require 'capybara/rspec'
require 'capybara/dsl'
require 'rack/test'
require 'timecop'

Capybara.app = Sinatra::Application

#for routes to work
require_relative '../../app/app.rb'

require_relative '../../auto-signup'

require_relative "../../experiment/create_experiment"

#testing helpers
require_relative '../../helpers.rb'



describe 'Experiment Dashboard' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  before(:each) do
    Experiment.all.to_a.each do |exper|
      exper.destroy
    end
  end 

  describe "controller" do 

    it "can access a normal page" do
      get '/'
      expect(last_response.status).to be 200
    end


    context "unauthorized" do 

      it "can't access admin page" do
        get '/admin'
        expect(last_response.status).to be 401
      end

    end


    context "bad authorization" do 
      
      it "doesn't auth" do 
        authorize 'bad', 'boy'
        get '/admin'
        expect(last_response.status).to be 401
      end

    end



    context "good authorization" do 
      
      it "can access page" do 
        authorize 'admin', 'ST'
        get '/admin'
        expect(last_response).to be_ok
      end

    end

  end

  describe "Creating Experiment", :type => :feature, :js => :true do
   
    before :each do 
      #configure HTTP header to authenticate
      visit '/'
      @url = current_url
      @tablica = @url.split("http://")
      @correct_url = @tablica[1]
      @admin_path = "http://admin:ST@#{@correct_url}admin"
    end
  
    it 'loads homepage' do
      visit '/'
      expect(page).to have_content "info@joinstorytime.com"
      expect(page).to_not have_content "early literacy sucks"
    end

    it 'loads authenticated page' do
      visit @admin_path
      expect(page).to have_content "Create Experiment"
    end

    it "submits Time experiment" do
      visit @admin_path
      page.choose('time_radio')
      page.select('5:30', from: 'time_option_1')
      page.select('6:30', from: 'time_option_2')
      page.select('6:45', from: 'time_option_3')

      page.select('40', from: 'users')
      page.select('5', from: 'weeks')

      page.fill_in('notes', with: "Here's the experiment!")
      click_button('create')

      expect(page).to have_content "Great, the experiment's set!"
    end

    it "submits Days experiment" do
      visit @admin_path
      page.choose('days_radio')
      page.select('1', from: 'days_option_1')
      page.select('2', from: 'days_option_2')
      page.select('3', from: 'days_option_3')

      page.select('30', from: 'users')
      page.select('4', from: 'weeks')

      page.fill_in('notes', with: "Here's the experiment!")
      click_button('create')

      expect(page).to have_content "Great, the experiment's set!"
    end

    it "submits for two options" do
      visit @admin_path
      page.choose('days_radio')
      page.select('1', from: 'days_option_1')
      page.select('2', from: 'days_option_2')

      page.select('30', from: 'users')
      page.select('4', from: 'weeks')

      page.fill_in('notes', with: "Here's the experiment!")
      click_button('create')

      expect(page).to have_content "Great, the experiment's set!"
    end

    it "fails if don't specify users and weeks" do
      visit @admin_path
      page.choose('days_radio')
      page.select('1', from: 'days_option_1')
      page.select('2', from: 'days_option_2')

      page.fill_in('notes', with: "Here's the experiment!")
      click_button('create')

      expect(page).to_not have_content "Great, the experiment's set!"
    end

    it "fails if don't specify day_start options" do
      visit @admin_path
      page.choose('days_radio')

      page.select('40', from: 'users')
      page.select('5', from: 'weeks')

      page.fill_in('notes', with: "Here's the experiment!")
      click_button('create')

      expect(page).to_not have_content "Great, the experiment's set!"
    end

    it "fails if don't specify time options" do
      visit @admin_path
      page.choose('time_radio')

      page.select('40', from: 'users')
      page.select('5', from: 'weeks')

      page.fill_in('notes', with: "Here's the experiment!")
      click_button('create')

      expect(page).to_not have_content "Great, the experiment's set!"
    end




    describe "create_experiment interfacing" do      

      before :each do
        REDIS.del DAYS_FOR_EXPERIMENT 

        visit @admin_path
        page.choose('time_radio')
        page.select('5:30', from: 'time_option_1')
        page.select('6:30', from: 'time_option_2')
        page.select('6:45', from: 'time_option_3')

        page.select('40', from: 'users')
        page.select('5', from: 'weeks')
        page.fill_in('notes', with: "Here's the experiment!")
        click_button('create') 
      end

      it "creates an experiment" do
        expect(Experiment.first).to_not be nil
        expect(Experiment.first.variable).to eq TIME_FLAG
      end

      it "gives proper attributes " do
        expect(Experiment.first.users_to_assign).to eq 40
        expect(Experiment.first.variable).to eq TIME_FLAG
        expect(REDIS.rpop(DAYS_FOR_EXPERIMENT)).to eq "35" 
      end

      # it "creates the right variations" do
      #   expect(Experiment)

      # end

    end


  end




end




