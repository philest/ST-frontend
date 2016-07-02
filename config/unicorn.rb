
worker_processes 3
timeout 30


app_path = File.expand_path(File.dirname(__FILE__) + '/..')

preload_app true # important for newrelic gem

working_directory app_path

# stderr_path app_path + '/log/unicorn.stderr.log'
# stdout_path app_path + '/log/unicorn.stdout.log'


listen app_path + '/tmp/unicorn.sock', backlog: 64


# commented out the job
# before_fork do |server, worker|
#    @sidekiq_pid ||= spawn("bundle exec sidekiq -q critical -q default -c 15 -v -r ./app/app.rb")
# end

# # If using ActiveRecord, disconnect (from the database) before forking.
# before_fork do |server, worker|
#   defined?(ActiveRecord::Base) &&
#     ActiveRecord::Base.connection.disconnect!
# end

# # After forking, restore your ActiveRecord connection.
# after_fork do |server, worker|
#   defined?(ActiveRecord::Base) &&
#     ActiveRecord::Base.establish_connection
# end



pid app_path + '/tmp/pids/unicorn.pid'

listen(3000, backlog: 64) if ENV['RACK_ENV'] == 'development'
