# helpers/sprint_helper.rb            Phil Esterman   
# 
# Helper to chop a longer SMS into many SMS, each less
# than 160 characters (for Sprint compatibility).
#  --------------------------------------------------------



##
#  Helper to chop a longer SMS into many SMS, each less
#  than 160 characters (for Sprint compatibility).
class Sprint

SPRINT_MAX_TEXT = 153 #leaves room for (1/6) at start (160 char msg)

	#  Helper to chop a longer SMS into many SMS, each less
	#  than 160 characters (for Sprint compatibility).
	#
	#  Paginates the SMS, and returns them as an array. 
	def self.chop(story) 

		sms = Array.new #array of texts to send seperately

		storyLen = story.length #characters in story

		totalChar = 0 #none counted so far

		startIndex = 0 

		smsNum = 1 #which sms you're on (starts with first)

		if storyLen <= 160
			return [story]

		else

			while (totalChar < storyLen - 1) #haven't divided up entire message yet

				if (totalChar + SPRINT_MAX_TEXT < storyLen) #if not on last message
					endIndex = startIndex + SPRINT_MAX_TEXT	
				else #if on last message
					endIndex = storyLen - 1 #endIndex is last index of story
				end

				just_spaces_end_index = endIndex #if there's no newlines, come back to this as starting endIndex


					while (story[endIndex - 1] != "\n" || (endIndex - 1) == startIndex) && endIndex > startIndex && endIndex != storyLen-1 do  #find the latest newline before endIndex
						endIndex -= 1
					end

					#there was no newLines
					if endIndex == startIndex
						#try again, looking for spaces
						endIndex = just_spaces_end_index

						while story[endIndex - 1] != " "
							endIndex -= 1
						end
					end

				smsLen = endIndex - startIndex #chars in sms

				totalChar += smsLen #chars dealt with so far

				#keep on biting off the ending \n's 
				if (story[endIndex - 1, 1] == "\n")
					msg = story[startIndex, smsLen-1]
				else
					msg = story[startIndex, smsLen]
				end


				if (story[startIndex] != "\n") #if it doesn't start with a newline...
				
					sms.push "(#{smsNum}/X)\n"+msg#...add two

				else
					sms.push "(#{smsNum}/X)"+msg#...just add one
				end


				startIndex = endIndex

				smsNum += 1 #on the next message

			end

			sms.each do |text|
				text.gsub!(/[\/][X][)]/, "\/#{smsNum-1})")
			end

			#if last char is newline, delete it. 
			sms.each_with_index do |text, index|
			   lastChar = text[text.length - 1]


			   if lastChar == "\n" 
			   	sms[index] = text[0..-2] #delete last char (by replacing the elt with a truncated version)
			   end

			end

			return sms

		end #160 or under char

	end

end

