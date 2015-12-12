#  variation.rb 	                          Phil Esterman		
# 
#  A variation for an A/B experiment: one particular
#  treatment. Bridges experiment and users. 
#
#  E.g. for an experiment on when to send messages, a
#  variation could be 7:00pm. 
#  --------------------------------------------------------

class Variation < ActiveRecord::Base
	belongs_to :experiment
	belongs_to :user
end
