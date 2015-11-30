require 'sinatra/r18n'

#set default locale to english
R18n.default_places { '../i18n' }
R18n::I18n.default = 'en'

i18n = R18n::I18n.new("en", ::R18n.default_places)
R18n.thread_set(i18n)
####

puts R18n.default_places
puts R18n.t.first_mms.to_s
puts R18n.t.start.sprint("2")


