# require './app/app'
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/activerecord/rake'
# Dir.glob('lib/tasks/*.rake').each { |r| load r}



require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  task :default => :spec

  # Refresh documentation. 
  task :yard do
  	sh 'rm -r public/doc'
  	sh 'yardoc'
  end
 

