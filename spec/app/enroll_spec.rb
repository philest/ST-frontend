ENV['RACK_ENV'] = "test"
require_relative "../spec_helper"

require 'capybara/rspec'
require 'rack/test'
require 'timecop'

require_relative '../../auto-signup'

#set default locale to english
# R18n.default_places = '../i18n/'
R18n::I18n.default = 'en'



DEFAULT_TIME = Time.new(2015, 6, 21, 17, 30, 0, "-04:00").utc #Default Time: 17:30:00 (5:30PM), EST

include Text


describe 'The StoryTime App' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

    before(:each) do
      Helpers.initialize_testing_vars
      NextMessageWorker.jobs.clear
      NewTextWorker.jobs.clear
      Sidekiq::Worker.clear_all
    end

    after(:each) do
      Sidekiq::Worker.clear_all
    end



    describe 'Autosignup' do


      it "properly saves locale info" do
        @user = User.find_by_phone("+15612125831")
        expect(@user).to be nil 
        
        Sidekiq::Testing.inline! do
          Signup.enroll(["+15612125831"], 'en', {Carrier: "ATT"})
        end

        @user = User.find_by_phone("+15612125831")
        @user.reload
        expect(@user).to_not be nil

        expect(@user.locale).to eq 'en'

        expect(Helpers.getMMSarr).to_not eq nil

      end

       it "works for es" do
        @user = User.find_by_phone("+15612125831")
        expect(@user).to be nil 
        
        Signup.enroll(["+15612125831"], 'es', {Carrier: "ATT"})
        @user = User.find_by_phone("+15612125831")
        @user.reload
        expect(@user).to_not be nil

        expect(@user.locale).to eq 'es'
        expect(Helpers.getSMSarr[0]).to_not eq Text::START_SMS_1 + "2" +Text::START_SMS_2
        puts Helpers.getSMSarr[0]
      end

      it "has getWait giving values every 2 seconds." do 
        Signup.initialize_user_count()
       
        (0..40).each do |num|
         expect(wait = Signup.getWait).to eq(num*8)
         
         if num == 0 || num == 40
          puts wait
         elsif num == 1
          puts '...'
         end


        end

      end

      it "enrolls with time 21:30 UTC (17:30 EST)" do
        Signup.enroll(["+15612125831"], 'en', {Carrier: "ATT"})
        @user = User.find_by_phone("+15612125831")

        expect(@user.time.zone).to eq "UTC"
        expect(@user.time.hour).to eq 21
        expect(@user.time.min).to eq 30
        puts @user.time
      end

      it "sends a sprint-chopped long message for ES on signup" do

        i18n = R18n::I18n.new('es', ::R18n.default_places) #this chunk seems to create a new R18n thread
        R18n.thread_set(i18n)

        R18n.set 'es'

        Sidekiq::Testing.inline! do
          Signup.enroll(["+15612125832"], 'es', {Carrier: Text::SPRINT})
        end
        @user = User.find_by_phone("+15612125832")



        expect(Helpers.getSMSarr.length).to eq 2
        expect(Helpers.getMMSarr.first).to eq R18n.t.first_mms

        puts Helpers.getSMSarr
      end

      it "doesn't chop long message for non-sprint ES on signup" do
        i18n = R18n::I18n.new('es', ::R18n.default_places)
        R18n.thread_set(i18n)
        R18n.set 'es'

        Sidekiq::Testing.inline! do
          Signup.enroll(["+15612125831"], 'es', {Carrier: "ATT"})
        end
        @user = User.find_by_phone("+15612125831")
      

        expect(Helpers.getSMSarr.length).to eq 1
        expect(Helpers.getMMSarr.first).to eq R18n.t.first_mms

        puts Helpers.getSMSarr
      end

      it "has different spanish/english responses" do 
        i18n = R18n::I18n.new('es', ::R18n.default_places)
        R18n.thread_set(i18n)
        R18n.set 'es'


        span_arr = [] #array of spanish commands

        #load array with commands
        span_arr.push R18n.t.commands.help.to_s
        span_arr.push R18n.t.commands.stop.to_s
        span_arr.push R18n.t.commands.text.to_s
        span_arr.push R18n.t.commands.story.to_s
        span_arr.push R18n.t.commands.sample.to_s
        span_arr.push R18n.t.commands.example.to_s
        span_arr.push R18n.t.commands.break.to_s

        span_arr.push R18n.t.start.normal.to_s
        span_arr.push R18n.t.start.sprint.to_s

        span_arr.push R18n.t.mms_update.to_s

        span_arr.push R18n.t.help.normal.to_s
        span_arr.push R18n.t.help.sprint.to_s

        span_arr.push R18n.t.error.no_option.to_s
        span_arr.push R18n.t.error.bad_choice.to_s

        span_arr.push R18n.t.first_mms.to_s

        i18n = R18n::I18n.new('en', ::R18n.default_places)
        R18n.thread_set(i18n)
        R18n.set 'en'
        engl_arr = [] #array of english commands

        #load array with commands
        engl_arr.push R18n.t.commands.help.to_s
        engl_arr.push R18n.t.commands.stop.to_s
        engl_arr.push R18n.t.commands.text.to_s
        engl_arr.push R18n.t.commands.story.to_s
        engl_arr.push R18n.t.commands.sample.to_s
        engl_arr.push R18n.t.commands.example.to_s
        engl_arr.push R18n.t.commands.break.to_s

        engl_arr.push R18n.t.start.normal.to_s
        engl_arr.push R18n.t.start.sprint.to_s

        engl_arr.push R18n.t.mms_update.to_s

        engl_arr.push R18n.t.help.normal.to_s
        engl_arr.push R18n.t.help.sprint.to_s

        engl_arr.push R18n.t.error.no_option.to_s
        engl_arr.push R18n.t.error.bad_choice.to_s

        engl_arr.push R18n.t.first_mms.to_s

        engl_arr.each_with_index do |engl, i|
          expect(engl).to_not eq span_arr[i] #the commands shouldn't be the same
          puts "#{engl} != #{span_arr[i]}"
        end  
      end

      it "recognizes Sprint v. Nonsprint" do

        Sidekiq::Testing.inline!
        # i18n = R18n::I18n.new('en', ::R18n.default_places)
        # R18n.thread_set(i18n)
        # R18n.set 'es'

        Signup.enroll(["+12032223333"], 'es', {Carrier: Text::SPRINT})
        Signup.enroll(["+14445556666"], 'es', {Carrier: "ATT"})

        expect(Helpers.getSMSarr.length).to eq 3 
        puts "Sp Part 1: #{Helpers.getSMSarr[0]}"
        puts "Sp Part 2: #{Helpers.getSMSarr[1]}"

        puts "Norm:  #{Helpers.getSMSarr[2]}"

      end


    end



end


