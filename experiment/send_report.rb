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

require 'statsample'
require 'descriptive_statistics'

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
		

		#arrays of 0 or 1 --> 0 for quit, 1 for continuing
		a_scores = {name: 'Var 1', scores: []}
		b_scores = {name: 'Var 2', scores: []}
		c_scores = {name: 'Var 3', scores: []}
		scores = [a_scores, b_scores, c_scores]


		#Label
		exper.variations.each do |var|
			print "%-30s" % ["Continuing:"]
		end
		print "\n"
		#Continuing
		exper.variations.each_with_index do |var, i|
			continuing = var.users.where("subscribed = true")
			print "%-30s" % [continuing.count]
			
			# add a 1 for each continuing, 0 for each dropoff
			continuing.count.times do
				scores[i][:scores].push 1
			end
			(var.users.count - continuing.count).times do
				scores[i][:scores].push 0
			end
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


		percents = []
		#Label
		exper.variations.each do |var|
			print "%-30s" % ["Percent continuing (%):"]
		end
		print "\n"
		#Total
		exper.variations.each_with_index do |var, i|
			continuing = var.users.where("subscribed = true")
			percent = 100 * (continuing.count * 1.0) / var.users.count
			print "%-30f" % [percent]
			percents.push( 
				{
				 variation: i+1, percent: percent
				}
			)
		end

		print "\n\n"

		if exper.notes != nil
			puts "%-30s" % ["Your inital notes:"]
			puts exper.notes
			print "\n"
		end

		print "\n\n"


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

		print "\n"

		print "Analysis:\n\n"

		#Label
		t_scores.each do |t|
			print "%-30s" % ["#{t[:pair]} T-score:"]
		end
		print "\n"
		#T-score
		t_scores.each do |t|
			print "%-30s" % ["#{t[:t_score]}"]
		end

		print "\n\n"

		#get the highest values of percent continuing
		current_highest = percents.first
		percents.each do |percent_hash|
			if percent_hash[:percent] > current_highest[:percent]
				current_highest = percent_hash
			end
		end

		highest = []
		#find multiples 
		percents.each do |percent_hash|
			if percent_hash[:percent] = current_highest[:percent]
				highest.push(percent_hash)
			end
		end

		print "Moving forward, it looks like the strongest "
		if highest.count == 1
			puts "variation is: "
		else
			puts "variations are: "
		end
		highest.each { |high| print "Variation #{high[:variation]}   " }
		print "\n\n"
		if highest.count == 1
			print "This "
		else
			print "These "
		end
		puts "had the highest percent of parents continuing: #{current_highest[:percent]}%"
		print "\n"
		puts "But-- given the t-score calculated-- this may be due to chance. Refer to the t-table in the link below to see the probability the result is meaningful."
		print "\n"
		puts "t-table: http://www.sjsu.edu/faculty/gerstman/StatPrimer/t-table.pdf"



		print "\n\n"


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






