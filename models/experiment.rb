#  experiment.rb 	                          Phil Esterman		
# 
#  A model for an A/B experiment. Each experiment has many 
#  variations, which
#
#  Example: an experiment on when to send messages could
#  have variations of 6:00pm, 6:30pm, and 7:00pm, and a
#  pool of users each randomly assigned to one. 
#  --------------------------------------------------------

class Experiment < ActiveRecord::Base
	has_many :variations
	has_many :users, through: :variations
end
