ENV['RACK_ENV'] = "test"

require_relative "./spec_helper"

require 'capybara/rspec'
require 'rack/test'

require_relative '../helpers'

# require_relative '../config/environments'

puts ENV["REDISTOGO_URL"] + "\n\n\n\n"


describe 'The StoryTime Workers' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end


   describe "ChoiceWorker" do


    before(:each) do
        ChoiceWorker.jobs.clear
        NextMessageWorker.jobs.clear
        Helpers.initialize_testing_vars
        @user = User.create(phone: "555", awaiting_choice: true, series_number: 0)
        Helpers.testCred
    end

    after(:each) do
      Helpers.testCredOff
    end

      it "properly enques a choiceWorker" do
      expect {
          ChoiceWorker.perform_async("+15612125831")
      }.to change(ChoiceWorker.jobs, :size).by(1)
      end



      it "starts with none, then adds more one" do
        expect(ChoiceWorker.jobs.size).to eq(0)
        ChoiceWorker.perform_async("+15612125831")
        expect(ChoiceWorker.jobs.size).to eq(1)
      end

      # SMS TESTS
    it "isn't there before" do
      expect(User.find_by_phone("444")).to eq(nil)
    end

    it "properly enques a choiceWorker" do 
     get '/test/555/p/ATT'
      expect {
        NextMessageWorker.jobs.size.to eq(1)
      }
    end

    it "properly doesn't enque a choiceWorker if bad choice" do 
     get '/test/555/z/ATT'
      expect {
        NextMessageWorker.jobs.size.to eq(0)
      }
    end

    it "properly doesn't enque a choiceWorker-- even with previously valid option-- on diff day" do 
     @user.update(series_number: 1)
     @user.reload
     get '/test/555/p/ATT'
      expect {
        NextMessageWorker.jobs.size.to eq(0)
      }
    end

    #VALID TEXTS

    it "gets the choice SMS in right order for first one" do
      get '/test/555/p/ATT'
      @user.reload
      messageSeriesHash = MessageSeries.getMessageSeriesHash
      story = messageSeriesHash[@user.series_choice + @user.series_number.to_s][0]

      expect(NextMessageWorker.jobs.size).to eq(1)
      NextMessageWorker.drain
      expect(NextMessageWorker.jobs.size).to eq(0)

      expect(Helpers.getSMSarr).to eq([].push story.getSMS)
    end


    it "gets the choice MMs in right order for first one" do
      get '/test/555/p/ATT'
      @user.reload
      messageSeriesHash = MessageSeries.getMessageSeriesHash
      story = messageSeriesHash[@user.series_choice + @user.series_number.to_s][0]

      expect(NextMessageWorker.jobs.size).to eq(1)
      NextMessageWorker.drain
      expect(NextMessageWorker.jobs.size).to eq(0)

      expect(Helpers.getMMSarr).to eq(story.getMmsArr)
      expect(Helpers.getMMSarr).not_to eq(nil)

    end











    # it "has all the first_text Brandon S-MS in right order" do
    #   get '/test/556/STORY/ATT'
    #   expect(ChoiceWorker.jobs.size).to eq(1)
    #   ChoiceWorker.drain
    #   expect(ChoiceWorker.jobs.size).to eq(0)
    #   expect(Helpers.getSMSarr).to eq([START_SMS_1 + "2" + START_SMS_2].push ChoiceWorker::FIRST_SMS)
    # end

    # it "has all the first_text Brandon M-ms in right order" do
    #   get '/test/556/STORY/ATT'
    #   expect(ChoiceWorker.jobs.size).to eq(1)
    #   ChoiceWorker.drain
    #   expect(ChoiceWorker.jobs.size).to eq(0)
    #   expect(Helpers.getMMSarr).to eq(ChoiceWorker::FIRST_MMS)
    # end

    
    # it "has all the SAMPLE S-MS in right order" do
    #   get '/test/556/SAMPLE/ATT'
    #   expect(ChoiceWorker.jobs.size).to eq(1)
    #   ChoiceWorker.drain
    #   expect(ChoiceWorker.jobs.size).to eq(0)
    #   expect(Helpers.getSMSarr).to eq([ChoiceWorker::SAMPLE_SMS])
    # end   

    # it "has all the SAMPLE M-MS in right order" do
    #   get '/test/556/SAMPLE/ATT'
    #   expect(ChoiceWorker.jobs.size).to eq(1)
    #   ChoiceWorker.drain
    #   expect(ChoiceWorker.jobs.size).to eq(0)
    #   expect(Helpers.getMMSarr).to eq(ChoiceWorker::FIRST_MMS)
    # end   




  end 

end


