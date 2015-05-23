
worker_processes 3
timeout 30

app_path = File.expand_path(File.dirname(__FILE__) + '/..')



stderr_path app_path + '/log/unicorn.stderr.log'
stdout_path app_path + '/log/unicorn.stdout.log'


listen app_path + '/tmp/unicorn.sock', backlog: 64
listen 8080, :tcp_nopush => true



before_fork do |server, worker|
   @sidekiq_pid ||= spawn("bundle exec sidekiq -c 5 -v -r ./app.rb")
end

# If using ActiveRecord, disconnect (from the database) before forking.
before_fork do |server, worker|
  defined?(ActiveRecord::Base) &&
    ActiveRecord::Base.connection.disconnect!
end

# After forking, restore your ActiveRecord connection.
after_fork do |server, worker|
  defined?(ActiveRecord::Base) &&
    ActiveRecord::Base.establish_connection
end


working_directory app_path

pid app_path + '/tmp/pids/unicorn.pid'

listen(3000, backlog: 64) if ENV['RACK_ENV'] == 'development'

stderr_path app_path + '/log/unicorn.stderr.log'
stdout_path app_path + '/log/unicorn.stdout.log'

