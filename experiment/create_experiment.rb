#  experiment/create_experiment.rb            Phil Esterman		
# 
#  Create experiment and variations, save into DB.  
#  --------------------------------------------------------

#add experiment & variation models
require_relative '../models/experiment'
require_relative '../models/variation'

require 'sinatra'
require 'sinatra/activerecord' #sinatra w/ DB

#redis
require 'redis'
require_relative '../config/environments'
require_relative '../config/initializers/redis'

#dst info
require_relative '../lib/set_time'

#the number of days until report results
DAYS_FOR_EXPERIMENT = "days_for_experiment"

#Flags for valid variables to experiment on 

#time to receive story
TIME_FLAG = "TIME" 
#how many days/week, to start
DAYS_TO_START_FLAG = "DAYS TO START"

VALID_FLAGS = [TIME_FLAG, DAYS_TO_START_FLAG]

#added to pm times to get 24-hour clock time
TO_24_HOUR_OFFSET = 12

# Create an experiment, along with all it's associatied
# variations. 
# 
# variable    - the String of what to experiment on
# options_arr - the Array of what values the variable should take.
#             			For time: [HH,MM] pairs. E.g. [06,30]
# 						for 6:30PM EST (12-hour clock, assumes PM)					
# users       - the Integer num of next users who will be enrolled
# 						in the experiment.
# days		  - the Integer number of days experiment should wait
# 						until sending results.
#
def create_experiment(variable,
					  options_arr,
					  users,
					  days)
	
	if !VALID_FLAGS.include? variable
		raise ArgumentError.new("Must experiment with a valid option.")
	end


	#check that Array isn't empty.
	if (options_arr.is_a? Array) &&
	   (options_arr.empty?)

		raise ArgumentError.new("options_arr must not be empty.")
	end

	# store the number of days in a queue,
	# to set end_date for DAYS time ahead
	# when first enroll users
	REDIS.lpush DAYS_FOR_EXPERIMENT, days


	exper = Experiment.create(variable: variable,
					          users_to_assign: users)

	# Every option is a varation. 
	options_arr.each do |option| 

		if variable == "TIME"

			unless (option.first.is_a? Fixnum) &&
				   (option.last.is_a? Fixnum)

				raise ArgumentError.new('[HH,MM] must a Fixnums.')
			end

			unless (option.first < 12 && option.first > 0) &&
				   (option.last < 60 && option.first >= 0)
			
				raise ArgumentError.new('Time must be between 1 and 11:59pm')
			end

			unless option.count == 2
				raise ArgumentError.new('Must have 2 values in array.')
			end


			if is_dst?
				est_to_utc_offset = 4
			else
				est_to_utc_offset = 5
			end

			#convert the time [5,30] to UTC by adding the offset
			t = Time.utc(2015, Time.now.month, Time.now.day, option.first +
									 est_to_utc_offset + 
									 TO_24_HOUR_OFFSET, 
									 option.last, 0)
			
			var = Variation.create(date_option: t, option: t.to_s) 
		else
			var = Variation.create(option: option.to_s)
		end

		# set it as part of experiment. 
		exper.variations.push var
	end


end