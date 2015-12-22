#  experiment/send_report.rb            Phil Esterman     
# 
#  Send final report on experiment results, delete
#  experiment.   
#  --------------------------------------------------------

#add experiment & variation models
require_relative '../models/experiment'
require_relative '../models/variation'
require_relative '../models/user'

require 'pony'
require_relative '../config/pony'


SEC_IN_DAY = 86400.0

def send_report(experiment_id)

	exper = Experiment.find(experiment_id)

				#capture stdout into the string.
	email_body = with_captured_stdout {

		puts "Your experiment has finished! Here's an overview of the results:\n\n\n"

		#Experiment name
		puts "%-30s" % ["Experiment:"]
		puts "%-30s" % [exper.variable]

		puts "\n\n"

		users = 0
		exper.variations.each do |var|
			users = users + var.users.count
		end
		puts "%-30s" % ["Users:"]
		print "\n"
		puts "%-30s" % [users]

		puts "\n\n"

		puts "%-30s" % ["Days:"]
		print "\n"
		puts "%-30f" % [(Time.now - exper.created_at) / SEC_IN_DAY ]

		puts "\n\n"



		#Label
		exper.variations.each_with_index do |var, i|
			if (i < 2) 
				print "%-30s" % ["Variation #{i+1}"]
			else 
				puts "Variation #{i + 1}\n"
			end
		end
		puts "\n"
		#Option
		exper.variations.each do |var|
			print "%-30s" % [var.option]
		end
			puts "\n\n"
		
		#Label
		exper.variations.each do |var|
			print "%-30s" % ["Continuing:"]
		end
		print "\n"
		#Continuing
		exper.variations.each do |var|
			continuing = var.users.where("subscribed = true")
			print "%-30s" % [continuing.count]
		end

		puts "\n\n"

		#Label
		exper.variations.each do |var|
			print "%-30s" % ["Total:"]
		end
		print "\n"
		#Total
		exper.variations.each do |var|
			print "%-30d" % [var.users.count]
		end
		print "\n\n"

		#Label
		exper.variations.each do |var|
			print "%-30s" % ["Percent continuing (%):"]
		end
		print "\n"
		#Total
		exper.variations.each_with_index do |var, i|
			continuing = var.users.where("subscribed = true")

			print "%-30f" % [100 * (continuing.count * 1.0) / var.users.count]
		end

		print "\n\n"

		if exper.notes != nil
			puts "%-30s" % ["Your inital notes:"]
			puts exper.notes
			print "\n"
		end

		exper.update(active: false)
	}


	#email us the results
	if MODE == "production"
      Pony.mail(:to => 'phil.esterman@yale.edu',
      		:cc => "henok.addis@yale.edu",
            :from => 'phil.esterman@yale.edu',
            :subject => 'StoryTime: Experiment Results.',
            :body => email_body,
            :charset => 'UTF-8')
	else
		print email_body
	end



end 


# capture stdout and return it as a string/
# ensure clause restores $stdout.
def with_captured_stdout
  begin
    old_stdout = $stdout
    $stdout = StringIO.new('','w')
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end
end






