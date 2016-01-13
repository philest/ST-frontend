require_relative './story'


class StorySeries

@@storySeriesHash = Hash.new

#the code is the letter (series choice) and series number, ex. p1 for puppy on series numbre 1
def initialize(messageArray, code) 
	@storySeries = messageArray
	@code=code
	@@storySeriesHash[@code] = @storySeries
end


def self.getStorySeriesHash
	return @@storySeriesHash
end


def self.codeIsInHash(code)
	if @@storySeriesHash[code] == nil
		return false
	else
		return true
	end
end





##Create Messages, Create Series from Messages






end