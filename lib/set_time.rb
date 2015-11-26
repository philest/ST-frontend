## Configure the default UTC time to get stories
## =>  (5:30pm EST)


#time now, in EST. 
est_time = Time.new(Time.now.year, Time.now.month, Time.now.day,
	 Time.now.hour, Time.now.min, Time.now.sec, "-05:00")

#adjust the UTC time for EST daylight savings 
if est_time.dst? == true						
	DEFAULT_TIME = Time.utc(2015, 6, 21, 21, 30, 0) 
		#21:30 UTC (17:30 EST --> 5:30 PM on East Coast)
else 											
	DEFAULT_TIME = Time.utc(2015, 6, 21, 22, 30, 0) 
		#22:30 UTC (17:30 EST --> 5:30 PM on East Coast)
end

TIME_DST = Time.utc(2015, 6, 21, 21, 30, 0) 

TIME_NO_DST = Time.utc(2015, 6, 21, 22, 30, 0)


#ensure TEST always has DST time. 
if ENV['RACK_ENV'] == "test"
	DEFAULT_TIME = TIME_DST
end 

