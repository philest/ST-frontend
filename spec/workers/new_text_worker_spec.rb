require_relative "../spec_helper"

require 'capybara/rspec'
require 'rack/test'
require 'timecop'

require 'time'
require 'active_support/all'

require_relative '../../helpers/twilio_helper'
require_relative '../../stories/story'
require_relative '../../stories/storySeries'
require_relative '../../i18n/constants'

require_relative '../../workers/new_text_worker'

SLEEP_SCALE ||= 860

SLEEP_TIME ||= (1/ 8.0)


#clean up leftover jobs
 Sidekiq::Worker.clear_all


describe 'The NewTextWorker' do
  include Rack::Test::Methods
  include Text
  def app
    Sinatra::Application
  end


  SINGLE_SPACE_LONG = ". If you can't receive picture msgs, reply TEXT for text-only stories.
  Remember that looking at screens within two hours of bedtime can delay children's sleep and carry health risks, so read StoryTime earlier in the day.
  Normal text rates may apply. For help or feedback, please contact our director, Phil, at 561-212-5831." 
  
  SMS = "This is a test SMS"


    before(:each) do
        User.create(phone: "+15612125834")
        NewTextWorker.jobs.clear
        TwilioHelper.initialize_testing_vars
        Timecop.return
        User.create(phone: "+15612125832")
        Sidekiq::Testing.inline!
    end

    after(:each) do
      Timecop.return
    end


    it "properly adds jobs after calling NextMessageWorker" do
      Sidekiq::Testing.fake! do 
        expect(NewTextWorker.jobs.size).to eq 0
        NewTextWorker.perform_in(20.seconds, SMS, NOT_STORY, "+15612125832")
        expect(NewTextWorker.jobs.size).to eq 1 
        puts "jobs: #{NewTextWorker.jobs.size}"
      end
    end

    it "properly sends out a single  SMS" do
      Sidekiq::Testing.fake! do 
        sms = "This is a test!" 
        NewTextWorker.perform_in(20.seconds, sms, NOT_STORY, "+15612125834")
        expect(NewTextWorker.jobs.size).to eq 1 
        NewTextWorker.drain

        expect(TwilioHelper.getSMSarr).to eq [sms]
        expect(TwilioHelper.getMMSarr).to eq []
      end
    end

    it "sends out a long SMS to Sprint in the seperate chunks" do

        @user = create(:user, carrier: Text::SPRINT)

        NewTextWorker.perform_async(SINGLE_SPACE_LONG, NOT_STORY, @user.phone)

      expect(TwilioHelper.getSMSarr.size).to_not eq 1
      expect(TwilioHelper.getSMSarr.size).to_not eq 0

      puts TwilioHelper.getSMSarr

    end


    it "Concatenates a long SMS to NON-SPrint in one piece" do
        @user = create(:user, carrier: 'ATT')

        NewTextWorker.perform_async(SINGLE_SPACE_LONG, NOT_STORY, @user.phone)

        expect(TwilioHelper.getSMSarr.first).to eq SINGLE_SPACE_LONG
        expect(TwilioHelper.getSMSarr.size).to eq 1
    end

    it "sends a 1 piece SMS to sprint in... one piece (160 char), w/o numbering" do
      user = create(:user)

      NewTextWorker.perform_async(Text::HELP_SPRINT_1 + "Tue/Th" + Text::HELP_SPRINT_2, NOT_STORY, user.phone)

      # expect(TwilioHelper.getSMSarr.size).to eq 1

      expect(TwilioHelper.getSMSarr.first).to eq Text::HELP_SPRINT_1 + "Tue/Th" + Text::HELP_SPRINT_2
      expect(TwilioHelper.getSMSarr.size).to eq 1

      puts TwilioHelper.getSMSarr[1]
    end





      



end
