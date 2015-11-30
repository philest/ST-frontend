require 'rubygems'
require 'twilio-ruby'
require_relative './sprint'
require 'sinatra/r18n'

#set default locale to english
R18n::I18n.default = 'en'

account_sid = 'ACea17e0bba30660770f62b1e28e126944'
auth_token = '716e0547bbd82c179b9aae8ebfef0e95'

@client = Twilio::REST::Client.new account_sid, auth_token

# sprintArr = Sprint.chop(SMS)

phone = "+15612125831" 

            # R18n.default_places = './i18n/'


            # require 'pry'
            # binding.pry

            i18n = R18n::I18n.new('en', ::R18n.default_places)
            R18n.thread_set(i18n)


                #send first picture
            R18n.set 'en'


            message = @client.account.messages.create(
                :to => phone,     # Replace with your phone number
                :from => "+12032023505",
                :body => R18n.t.error.no_option.to_s)


            puts "sent!"
            # sleep 10



            #     message = @client.account.messages.create(
            #         :to => phone,     # Replace with your phone number
            #         :from => "+12032023505",
            #         :body => body,
            #         :media => "http://www.joinstorytime.com/images/d_sp.png")   # Replace with your Twilio number

