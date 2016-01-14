# require './app/app'
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/activerecord/rake'
# Dir.glob('lib/tasks/*.rake').each { |r| load r}

configure :development, :test do
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task :default => :spec
end

  # Refresh documentation. 
  task :yard do
  	sh 'rm -r public/doc'
  	sh 'bundle exec yardoc'
  end

  task :main_worker do 
  	sh 'bundle exec rspec -fd spec/workers/main_worker_spec.rb'
  end
 

