require_relative './story'


class MessageSeries

@@messageSeriesHash = Hash.new

#the code is the letter (series choice) and series number, ex. p1 for puppy on series numbre 1
def initialize(messageArray, code) 
	@messageSeries = messageArray
	@code=code
	@@messageSeriesHash[@code] = @messageSeries
end


def self.getMessageSeriesHash
	return @@messageSeriesHash
end


def self.codeIsInHash(code)
	if @@messageSeriesHash[code] == nil
		return false
	else
		return true
	end
end





##Create Messages, Create Series from Messages






end