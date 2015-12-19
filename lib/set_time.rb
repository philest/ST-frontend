## Configure the default UTC time to get stories
## =>  (5:30pm EST)

# Return whether it's daylight savings time in EST
# TODO fix hack based on months
def is_dst?
	if (Time.now.month >= 3) && (Time.now.month < 11)
		return true
	else
		return false
	end
end


TIME_DST = Time.utc(2015, 6, 21, 21, 30, 0) 
#21:30 UTC (17:30 EST --> 5:30 PM on East Coast)
#-04:00

TIME_NO_DST = Time.utc(2015, 6, 21, 22, 30, 0)
#22:30 UTC (17:30 EST --> 5:30 PM on East Coast)
#-05:00


#adjust the UTC time for EST daylight savings 
if is_dst?						
	DEFAULT_TIME = TIME_DST 
else 											
	DEFAULT_TIME = TIME_NO_DST 
end

#ensure TEST always has DST time. 
if ENV['RACK_ENV'] == "test"
	DEFAULT_TIME = TIME_DST
end 
