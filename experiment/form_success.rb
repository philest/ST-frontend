
##
# Create an experiment from the params
# selected on the experiment dashboard.
#  
def form_success
    # the options selected during experiment
    # creation. 
    options_arr = []

    case params[:variable]
    when TIME_FLAG
        #load selected options. 
        options_arr.push(params[:time_option_1],
                         params[:time_option_2],
                         params[:time_option_3])
        #clean out nil's
        options_arr.delete(nil)

        #to fit create_experiment format: 
        #split '5:30' into ['5', '30']  
        options_arr.map! do |opt|
            opt.split(':')
        end

        #convert to ints
        options_arr.map! do |first, second|
            [].push(first.to_i, second.to_i)
        end

    when DAYS_TO_START_FLAG
        options_arr.push(params[:days_option_1],
                         params[:days_option_2],
                         params[:days_option_3])
        #clean out nil's
        options_arr.delete(nil)
        #string->int ['1', '2'] -> [1,2]
        options_arr.map! { |opt| opt.to_i}
    end


    begin 
        # fit create_experiment format: 
        # convert weeks to days, convert to int.
        create_experiment(params[:variable],
                          options_arr,
                          params[:users].to_i,
                          7*params[:weeks].to_i,
                          [params[:notes]])


        "Great, the experiment's set!"
  
    rescue ArgumentError => e 
        $stderr.print "Experiment not created!\n\nArgumentError: #{e}"
        $stderr.print  "\n\nBacktrace:\n\n"
        (1..12).each { $stderr.print e.backtrace.shift }
        "Experiment not created!\n\nArgumentError: #{e}\n\n Backtrace #{e.backtrace}"
    rescue NoMethodError => e
        $stderr.print "Experiment not created!\n\nNoMethodError: #{e}"
        $stderr.print  "\n\nBacktrace:\n\n"
        (1..12).each { $stderr.print e.backtrace.shift }
        "Experiment not created!\n\nNoMethodError: #{e}\n\n Backtrace #{e.backtrace}"
    end
end
