class Age

DAYS_IN_YEAR = 365
	#takes string of birthdate in MMDDYY formate (ex 091412 for Sept 14, 2012)
	def self.InYears(birthdate)

		currDate = Time.new

		#the days now
		daysNow = (currDate.year * 365) + (currDate.month * 30) + currDate.day

		#the days at birth
		daysThen = ((2000 + birthdate[4,2].to_i) * 365) + (birthdate[0,2].to_i * 30) + birthdate[2,2].to_i 

		ageInDays = daysNow - daysThen

		years = ageInDays / DAYS_IN_YEAR

		return years

	end	

end