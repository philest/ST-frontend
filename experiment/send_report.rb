#  experiment/send_report.rb            Phil Esterman     
# 
#  Send final report on experiment results, delete
#  experiment.   
#  --------------------------------------------------------

#add experiment & variation models
require_relative '../models/experiment'
require_relative '../models/variation'
require_relative './experiment_constants'

include ExperimentConstants

def send_report(experiment_id)

	exper = Experiment.find(experiment_id)

	

end 
