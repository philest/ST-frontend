#Automating A/B Tests
Phil Esterman, CS458


##NOTES
This project relies on a suite of environment dependent tools— including a Postgres database and Redis data structure server. It also involves a extensive libraries not installed on the zoo (27, with a total of 98 dependencies). 

The only way to “see” the code working without having to enroll real families is in testing and development. For this, the code relies on Postgres and Redis to be properly configured and running locally. 

####Not Running on Zoo

After a full day of attempts, I have been unable to get the local databases and suite of libraries installed and working on the zoo.

####Specs to replace

To instead show functionally, I've written an extensive suite of tests that I've run locally and passed. I've included that output from passing tests-- along with extensive documentation-- below, to compensate for the code not running on the zoo.

To get a better sense of the code's feautures, look at the tests in `spec/experiment/`.


##Why

It’s cognitively exhausting to run A/B tests. The code additions always feel haphazard and unsystematic, and they take mental effort to implement again and again. For web and mobile apps, many tools exist to A/B visual choices and wording— but I don’t know of any to have simplified testing an app’s logic: the key variables of how it works.

I implemented a V1 of an interface to automate this A/B testing.



##Background
The interface is for-- and an extension of--  an existing personal project called [StoryTime](https://www.dropbox.com/s/7fuxc0xum6bv59o/About_StoryTime.pdf?dl=0). We’re a nonprofit scaling literacy for low-income families: to do it, we send illustrated kid’s stories by text message to families without books at home.



#Creating Experiments

##The Interface

The interface takes: 

- the variable to experiment on
- its values with which to experiment
- the number of new users who will receive the randomized options
- and how long the experiment should run (in weeks)
- some notes on the purpose of the experiment (optional)

It's implemented as an HTML form page with erb templating, with a ruby server called Sinatra. 


Here's a look: 


![image](https://i.imgur.com/pepNmQA.png?1)
The code can found in `views/experiment_dashboard.rb`.

###Testing it

Capybara and Rspec were used to simulate a user creating an experiment. Here's output from successfuly running the test suite. 

![Imgur](https://i.imgur.com/tX3Fv2G.png)

##The Backend

###The Model
Beyond a User model, creating experiments required models for Experiment and Variation-- along with associations between all three. 

Here's the resulting schema from ActiveRecord migrations and associations.

```ruby
ActiveRecord::Schema.define(version: 20151222002125) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "experiments", force: :cascade do |t|
    t.string   "variable"
    t.integer  "users_to_assign"
    t.datetime "end_date"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.text     "notes"
    t.boolean  "active",          default: true
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "phone"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "child_birthdate"
    t.integer  "child_age",            default: 4
    t.string   "child_name"
    t.string   "carrier"
    t.integer  "story_number",         default: 0
    t.boolean  "subscribed",           default: true
    t.boolean  "mms",                  default: true
    t.integer  "last_feedback",        default: -1
    t.integer  "days_per_week"
    t.boolean  "set_time",             default: false
    t.boolean  "set_birthdate",        default: false
    t.integer  "series_number",        default: 0
    t.string   "series_choice"
    t.integer  "next_index_in_series"
    t.boolean  "awaiting_choice",      default: false
    t.boolean  "sample",               default: false
    t.integer  "total_messages",       default: 0
    t.time     "time"
    t.boolean  "on_break",             default: false
    t.integer  "days_left_on_break"
    t.string   "locale"
    t.integer  "variation_id"
  end

  add_index "users", ["variation_id"], name: "index_users_on_variation_id", using: :btree

  create_table "variations", force: :cascade do |t|
    t.integer  "experiment_id"
    t.integer  "user_id"
    t.string   "option"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.datetime "date_option"
  end

  add_index "variations", ["experiment_id"], name: "index_variations_on_experiment_id", using: :btree
  add_index "variations", ["user_id"], name: "index_variations_on_user_id", using: :btree

end
```

 Specs for these could be found in `spec/model/`.
 


###create_experiment
`create_experiment` takes the options selected in the interface, then creates ActiveRecord instances of the `Experiment` and `Variations`. These are saved to the postgres database.

```ruby
#  experiment/create_experiment.rb            Phil Esterman     
# 
#  Create experiment and variations, save into DB.  
#  --------------------------------------------------------

# Create an experiment, along with all it's associatied
# variations. 
# 
# variable    - the String of what to experiment on
# options_arr - the Array of what values the variable should take.
#                       For time: [HH,MM] pairs. E.g. [06,30]
#                       for 6:30PM EST (12-hour clock, assumes PM)                  
# users       - the Integer num of next users who will be enrolled
#                       in the experiment.
# days        - the Integer number of days experiment should wait
#                       until sending results.
# *notes      - the String of comments on experiment or hypothesis
#
def create_experiment(variable,
                      options_arr,
                      users,
                      days,
                      *notes)
    
  if !ExperimentConstants::VALID_FLAGS.include? variable
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
  #inlude notes, if given
  if !notes.empty?
    exper.update(notes: notes.pop)
  end

  # Every option is a varation. 
  options_arr.each do |option| 

    case variable 

    when ExperimentConstants::TIME_FLAG

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
  
    when ExperimentConstants::DAYS_TO_START_FLAG

      if !(option.is_a? Fixnum) || (option <= 0)
        raise ArgumentError.new("Days_to_start must be positive integer.") 
      end

      var = Variation.create(option: option.to_s)
    end 

    # set it as part of experiment. 
    exper.variations.push var
  end


end
```
###Testing it 
To get a sense of it's functionally, check out the results from running the spec suite. 

![Imgur](https://i.imgur.com/EUisqm0.png)

The full suite could be found in `spec/experiment/`.


##Enrolling Users

After an experiment and its variations are created, users are assigned to a random variation when they are enrolled. That happens here in `app/enroll.rb`.

```ruby
	## ASSIGN TO EXPERIMENT VARIATION
	#  -get first experiment
	#  -assign user to one of its variation
	#  -alternate variations using modulo
	#
	if type == STORY    #grab first experiment with users left to assign
		if Experiment.where("active = true").count != 0 &&
		  (our_experiment = Experiment.where("active = true AND users_to_assign != '0'").first)

			users_to_assign = our_experiment.users_to_assign

			#get valid variations from first experiment
			variations = our_experiment.variations

			#user-count used to alternate which variation chosen
			#Eg. with three variations:
			# u1 -> v1, u2 -> v2 ... u4 -> v1, u5 - > v2
			var = variations[users_to_assign % variations.count]
			@user.variation = var #give user the variation
			var.users.push @user #give variation the user

			#save to DB (TODO: necessary?)
			#update user with experiment variation


			case our_experiment.variable
			when ExperimentConstants::TIME_FLAG
				 @user.update(time: var.date_option)
			when ExperimentConstants::DAYS_TO_START_FLAG
				 @user.update(days_per_week: var.option.to_i)
			end

			#update exp time by popping off REDIS last days set
			if our_experiment.end_date == nil 
				our_experiment.update(end_date: Time.now.utc + 
								        REDIS
								       .rpop(DAYS_FOR_EXPERIMENT)
								       .to_i
								       .days)
			end


			#one more user was assigned
			our_experiment.update(users_to_assign: users_to_assign - 1)
		
			@user.save
			var.save
			our_experiment.save


		end

	end
```

It's specs are mixed into `create_experiment`'s, shown above.


##Reporting Results

After the given number of weeks have passed, we produce a report that indicates: 

- the % persistence within each version
-  the signficance of the difference (given by a t-score)
-  a recommendation on which option to choose
-  an explanation for the recommendation

This report is then sent to me by email.  
 
###Checking Experiment's End
First, a background worker checks every few minutes whether any experiments have ended:


```ruby
#from workers/some_worker.rb

    begin
      #Experiment: Send report if completed-->i.e. past end_date! 
      Experiment.where("active = true").to_a.each do |exper|
        if (exper.end_date && Time.now > exper.end_date)
          send_report(exper.id)
        end
      end
    rescue StandardError => e
        $stderr.print "Experiment report not sent.\n\nError: #{e}"
        $stderr.print  "\n\nBacktrace:\n\n"
        (1..30).each { $stderr.print e.backtrace.shift }
    end
```

###Building the report
`experiment/send_report.rb` then creates the report by iterating through the experiment's variations, and checking what proportion of each variation's users continued with the programming (instead of not responding and quitting). 

###Calculating t-scores

It then calculates a two-sample-independent t-score for each pair of variations, to measure whether any difference was significant or due to chance.

The t-scores are calculated for every unique pair of variations using the Ruby statsample library.

```ruby
   #from experiment/send_report.rb

   #  scores = [
   #	1_scores = {name: 'Variation 1', scores: [some array of 1,0's...]}
   #    2_scores = {name: 'Variation 2', scores: [some array of 1,0's...]}
   #	3_scores = {name: 'Variation 3', scores: [some array of 1,0's...]} 
   #   ]

		combos = scores.combination(2).to_a
		t_scores = []
		combos.each do |a,b|
			a_name = a[:name]
			b_name = b[:name] 

			a = a[:scores]
			b = b[:scores]
			

			#plus 0.01 to SD to avoid division by zero
			t_scores.push(

				{ pair: "#{a_name} and #{b_name}",

				  t_score: Statsample::Test::T.two_sample_independent(a.mean, b.mean,  
			    a.standard_deviation + 0.01, b.standard_deviation + 0.01, a.count, b.count)
				}
			)
		end
```


##The Report



The report arrives by email:

![Imgur](https://i.imgur.com/BEsgs7F.png)

Here's a look:

```
Your experiment has finished! Here's an overview of the results:


Experiment:                   
TIME                          


Users:                        

5                             


Days:                         

7.000693                      


Variation 1                   Variation 2                   Variation 3

2015-01-01 23:45:00 UTC       2015-01-01 23:30:00 UTC       2015-01-01 22:45:00 UTC       

Continuing:                   Continuing:                   Continuing:                   
3                             1                             1                             

Total:                        Total:                        Total:                        
3                             1                             1                             

Percent continuing (%):       Percent continuing (%):       Percent continuing (%):       
100.000000                    100.000000                    100.000000                    




Analysis:

Var 1 and Var 2 T-score:      Var 1 and Var 3 T-score:      Var 2 and Var 3 T-score:      
0.0                           0.0                           0.0                           

Moving forward, it looks like the strongest variations are: 
Variation 1   Variation 2   Variation 3   

These had the highest percent of parents continuing: 100.0%

But-- given the t-score calculated-- this may be due to chance. Refer to the t-table in the link below to see the probability the result is meaningful.

t-table: http://www.sjsu.edu/faculty/gerstman/StatPrimer/t-table.pdf


```

##Shortcomings and Next Steps

###p-values
An immediate next step will be to calculate p-values from the t-scores to further automate interpreting how meaningful the differences in variations are. Ruby has weaker statistical libraries, and I found none that could translate a t-score into a p-value. 

With this, more nuance could be introduced into the recommendation and explanation system. The system will caution against choosing the best performing variation if the p-value is weak. 

###Visualizing experiments

A final step would be visualizing current and past experiments on the experiment dashboard. This will make experiments feel more concrete and allow knowledge to build over time. 