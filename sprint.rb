
@story = [ "StoryTime: Enjoy tonight's story:

	Now We Are Six

	When I was one,
	I had just begun.

	When I was two,
	I was nearly new.

	When I was three,
	I was hardly me.

	When I was four,
	I was not much more.

	When I was five,
	I was just alive.

	But now I am six,
	I'm as clever as clever.
	
	So I think I'll be six
	Now and forever.

	a)Ask your child how old they are and what their birthday is?

	b)Does your child think it’s possible to be 6 years old forever?
	
	c)What is the smallest number your child knows? The biggest? Can your child count all the way to it?",

	"StoryTime: Keep up the great work!

	Unscratchable Itch

	There is a spot that you can’t scratch
	Right between your shoulder blades,
	Like an egg that just won’t hatch
	Here you set and there it stay

	Turn and squirm and	try to reach it,
	Twist your neck and bend your back,

	Hear your elbows creak and creak,
	Stretch your fingers, now you bet it’s
	Going to reach –
	
	no that won’t get it-
	Hold your breath and stretch and pray,
	Only just an inch away,

	Worse than a sunbeam you can’t catch
	Is that one spot that
	You can’t scratch.

a)Is there a spot on your back that you can’t reach? Try the other hand! Can you reach your toes…without bending your knees!

b)Reread the first line of the poem. But this time, clap your hands as you say each syllable.
Have your child repeat the line. Help them clap their hands as they say each syllable.

c)Try this for the second line! The poet rhymes the word \"scratch\" with \"hatch.\" Can you think of any other words that rhyme with \"scratch?\" See if you can name 5!",
"StoryTime: Here's tonight's poem:

	Where the Sidewalk Ends

	There is a place where the sidewalk ends
	And before the street begins.
	And there the grass grows soft and white.
	And there the sun burns crimson bright
	And there the moon-bird rests from his flight
	To cool in the peppermint wind.

	Let us leave this place where the smoke blows black
	And the dark street winds and bends.
	Past the pits where the asphalt flowers grow
	We shall walk with a walk that is measured and slow,
	And watch where the chalk-white arrows go
	To the place where the sidewalk ends.

	Yes we'll walk with a walk that is measured and slow,
	And we'll go where the chalk-white arrows go,
	For the children, they mark, and the children,they know
	The place where the sidewalk ends.

a) Have you ever been to the end of the sidewalk? Would you want to go? What do you think it looks like there?

b) Reread the third line. Ask your child to repeat it. Try to think of 10 other words that start with the letter “g”! 
Can you make the shape of the letter “g” with your fingers? How about with your body?"]

	MAX_TEXT = 155 #leaves room for (1/6) at start (160 char msg)



def sprint(story) 

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

			while (story[endIndex-1] != "\n" || endIndex-1 == startIndex) && endIndex != storyLen-1 do  #find the latest newline before endIndex
				endIndex -= 1
			end

			if endIndex == startIndex #no newlines in block

				binding.pry

				endIndex = startIndex + MAX_TEXT #recharge endindex
				
				while story[endIndex-1] != " "
				endIndex -= 1
				end

			end

		smsLen = endIndex - startIndex #chars in sms

		totalChar += smsLen #chars dealt with so far

		sms.push "(#{smsNum}/X)"+story[startIndex, smsLen]

		startIndex = endIndex

		smsNum += 1 #on the next message

	end

	sms.each do |text|
		text.gsub!(/[\/][X][)]/, "\/#{smsNum-1})")
	end

	return sms

end


