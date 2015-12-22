#  experiment/send_report.rb            Phil Esterman     
# 
#  Send final report on experiment results, delete
#  experiment.   
#  --------------------------------------------------------

#add experiment & variation models
require_relative '../models/experiment'
require_relative '../models/variation'
require_relative '../models/user'


def send_report(experiment_id)

	exper = Experiment.find(experiment_id)


	exper.update(active: false)

end 
