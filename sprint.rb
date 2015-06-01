

MAX_TEXT = 153 #leaves room for (1/6) at start (160 char msg)

BREAK = "\n" #for Help Message

JEW = "StoryTime: Remember, you and your child can act out each orange word:

Activites:

a) Pretend you are farmers! Ask your child what types of crops are grown on the farm. Which crop is their favorite? Are there any animals?
 
b) Show your child the rhymes & have them repeat after you: “Soil and toil.” Ask which of the following words rhymes with toil: building, boring, boil."

class Sprint

def self.chop(story) 

	sms = Array.new #array of texts to send seperately

	storyLen = story.length #characters in story

	totalChar = 0 #none counted so far

	startIndex = 0 

	smsNum = 1 #which sms you're on (starts with first)

	while (totalChar < storyLen - 1) #haven't divided up entire message yet

		if (totalChar + MAX_TEXT < storyLen) #if not on last message
			endIndex = startIndex + MAX_TEXT	
		else #if on last message
			endIndex = storyLen - 1 #endIndex is last index of story
		end

			while (story[endIndex-1] != BREAK || endIndex-1 == startIndex) && endIndex != storyLen-1 do  #find the latest newline before endIndex
				endIndex -= 1
			end

			if endIndex == startIndex #no newlines in block

				endIndex = startIndex + MAX_TEXT #recharge endindex
				
				while story[endIndex-1] != " "
				endIndex -= 1
				end

			end

		smsLen = endIndex - startIndex #chars in sms

		totalChar += smsLen #chars dealt with so far


		if (story[startIndex] != "\n") #if it doesn't start with a newline...
	
		sms.push "(#{smsNum}/X)\n"+story[startIndex, smsLen] #...add two

		else
		sms.push "(#{smsNum}/X)"+story[startIndex, smsLen]#...just add one
		end


		startIndex = endIndex

		smsNum += 1 #on the next message

	end

	sms.each do |text|
		text.gsub!(/[\/][X][)]/, "\/#{smsNum-1})")
	end

	return sms

end

end

