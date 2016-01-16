Airbrake.configure do |c|
  c.project_id = ENV['AIRBRAKE_API_KEY']
  c.project_key = ENV['AIRBRAKE_PROJECT_ID']

  # Display debug output.
  c.logger.level = Logger::DEBUG
end
