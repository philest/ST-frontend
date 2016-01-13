#  stories/storySeries.rb                     Phil Esterman   
# 
#  StorySeries are hashes of multiple stories, sent
#  episodically. 
#  --------------------------------------------------------

require_relative './story'

##
#  StorySeries are hashes of multiple stories, sent
#  episodically. 
class StorySeries

# The master hash of all series. 
@@storySeriesHash = Hash.new

# Create a new series. 
#
# [code] is the letter (series choice) and series number
#   ex. p1 for puppy on series number 1
#
# [storyArray] is an array of the story objects
# that make up the series.
#
def initialize(storyArray, code) 
	@storySeries = storyArray
	@code=code
	@@storySeriesHash[@code] = @storySeries
end


# Get the hash of all series. 
def self.getStorySeriesHash
	return @@storySeriesHash
end

# Check whether the code corresponds to an actual series. 
def self.codeIsInHash(code)
	if @@storySeriesHash[code] == nil
		return false
	else
		return true
	end
end


end