require 'pry'

class Jew

  def self.convertTimeTo24(oldTime)


    len = oldTime.length
    hoursEndIndex = oldTime.index(':')
    
    hours = oldTime[0,hoursEndIndex]
    hours = (hours.to_i + 12).to_s


    if oldTime[len-2,len] == "pm" && hours != 12 #if pm, add 12 to hours      

      colonAndMinutes = oldTime[hoursEndIndex, len-2]
      cleanedTime= hours + colonAndMinutes

    else #am version
      cleanedTime = oldTime[0,len-2]
    end

    binding.pry

    return cleanedTime

  end

end