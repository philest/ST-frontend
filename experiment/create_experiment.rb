#  experiment/create_experiment.rb            Phil Esterman		
# 
#  Create experiment and variations, save into DB.  
#  --------------------------------------------------------

#add experiment & variation models
require_relative '../models/experiment'
require_relative '../models/variation'

require 'sinatra'
require 'sinatra/activerecord' #sinatra w/ DB

require 'as-duration'

#redis
require 'redis'
require_relative '../config/environments'
require_relative '../config/initializers/redis'

#the number of days until report results
DAYS_FOR_EXPERIMENT = "days_for_experiment"

# Create an experiment, along with all it's associatied
# variations. 
# 
# variable    - the String of what to experiment on
# options_arr - the Array of what values the variable should take
# users       - the Integer num of next users who will be enrolled
# 						in the experiment.
# days		  - the Integer number of days experiment should wait
# 						until sending results.
#
def create_experiment(variable,
					  options_arr,
					  users,
					  days)

	# store the number of days in a queue,
	# to set end_date for DAYS time ahead
	# when first enroll users
	REDIS.lpush DAYS_FOR_EXPERIMENT, days


	Experiment.create(variable: variable,
					  users_to_assign: users)

end