require_relative "../spec_helper"

require 'capybara/rspec'
require 'rack/test'
require 'timecop'

require 'time'
require 'active_support/all'

require_relative '../../helpers'
require_relative '../../stories/story'
require_relative '../../stories/storySeries'
require_relative '../../i18n/constants'

require_relative '../../workers/new_text_worker'
# require_relative '../workers/first_text_worker'

SLEEP_SCALE = 860

SLEEP_TIME = (1/ 8.0)


HELP = "help now"
STOP = "stop now"

SPRINT_CARRIER = "Sprint Spectrum, L.P."

START_SMS_1 = "StoryTime: Welcome to StoryTime, free pre-k stories by text! You'll get "

START_SMS_2 = " stories/week-- the first is on the way!\n\nText " + HELP + " for help, or " + STOP + " to cancel."


MMS_ARR = ["http://i.imgur.com/CG1DxZd.jpg", "http://i.imgur.com/GEc0dhT.jpg"]

SMS = "This is a test SMS"

PHONE = "+15612125832"

SPRINT_QUERY_STRING = 'Sprint%20Spectrum%2C%20L%2EP%2E'

SP_PHONE = '+15619008229'

SINGLE_SPACE_LONG = ". If you can't receive picture msgs, reply TEXT for text-only stories.
Remember that looking at screens within two hours of bedtime can delay children's sleep and carry health risks, so read StoryTime earlier in the day.
Normal text rates may apply. For help or feedback, please contact our director, Phil, at 561-212-5831." 

#clean up leftover jobs
 Sidekiq::Worker.clear_all


describe 'The NextMessageWorker' do
  include Rack::Test::Methods
  include Text
  def app
    Sinatra::Application
  end


    before(:each) do
        User.create(phone: "+15612125834")
        NewTextWorker.jobs.clear
        Helpers.initialize_testing_vars
        Timecop.return
        Helpers.testSleep
        User.create(phone: "+15612125832")
    end

    after(:each) do
      Timecop.return
    end


    it "properly adds jobs after calling NextMessageWorker" do
      expect(NewTextWorker.jobs.size).to eq 0
      NewTextWorker.perform_in(20.seconds, SMS, NOT_STORY, "+15612125832")
      expect(NewTextWorker.jobs.size).to eq 1 
      puts "jobs: #{NewTextWorker.jobs.size}"
    end

    it "properly sends out a single  SMS" do
      sms = "This is a test!" 
      NewTextWorker.perform_in(20.seconds, sms, NOT_STORY, "+15612125834")
      expect(NewTextWorker.jobs.size).to eq 1 
      NewTextWorker.drain

      expect(Helpers.getSMSarr).to eq [sms]
      expect(Helpers.getMMSarr).to eq []
    end

    it "sends out a long SMS to Sprint in the seperate chunks" do
        # get 'test/' + SP_PHONE + "/STORY/"+SPRINT_QUERY_STRING
        # @user = User.find_by_phone SP_PHONE
        # @user.reload

        @user = create(:user)
        @user.update(carrier: SPRINT_CARRIER)

        NewTextWorker.perform_async(SINGLE_SPACE_LONG, NOT_STORY, @user.phone)
        NewTextWorker.drain

      expect(Helpers.getSMSarr.size).to_not eq 1
      expect(Helpers.getSMSarr.size).to_not eq 0

      puts Helpers.getSMSarr

    end


    it "Concatenates a long SMS to NON-SPrint in one piece" do
        @user = create(:user)
        @user.update(carrier: "ATT")

        NewTextWorker.perform_async(SINGLE_SPACE_LONG, NOT_STORY, @user.phone)
        NewTextWorker.drain

      # expect(Helpers.getSMSarr.size).to eq 1

        expect(Helpers.getSMSarr[1]).to eq SINGLE_SPACE_LONG
        expect(Helpers.getSMSarr.size).to eq 2
    end

    it "sends a 1 piece SMS to sprint in... one piece (160 char), w/o numbering" do
      get 'test/' + "+15612797798" + "/STORY/" + "ATT"
      @user = User.find_by_phone "+15612797798"
      @user.reload

      NewTextWorker.perform_async(Text::HELP_SPRINT_1 + "Tue/Th" + Text::HELP_SPRINT_2, NOT_STORY, @user.phone)
      NewTextWorker.drain

      # expect(Helpers.getSMSarr.size).to eq 1

      expect(Helpers.getSMSarr[1]).to eq Text::HELP_SPRINT_1 + "Tue/Th" + Text::HELP_SPRINT_2
      expect(Helpers.getSMSarr.size).to eq 2

      puts Helpers.getSMSarr[1]
    end





      



end
