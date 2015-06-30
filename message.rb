require_relative './messageSeries'

class Message

	def initialize(mmsArr, sms, poemSMS)
		@mmsArr=mmsArr
		@sms=sms
		@poemSMS= sms + "\n\n" + poemSMS
	end

	def setMmsArr(mmsArr)
		@mmsArr = mmsArr
	end

	def setSMS(sms)
		@sms = sms
	end

	def setPoemSMS(poemSMS)
		@poemSMS = poemSMS
	end

	def getMmsArr
		return @mmsArr
	end

	def getSMS
		return @sms
	end

	def getPoemSMS
		return @poemSMS
	end


	def self.getMessageArray
		return @@messageArray
	end

		@@messageArray = Array.new

		@@messageArray.push Message.new(["http://i.imgur.com/gNPKPSs.jpg", "http://i.imgur.com/SRDF3II.jpg", "http://i.imgur.com/iSVBGu4.jpg"],
	      "StoryTime: Here's your new story... beware of hungry crocodiles!",
	      "The biggest crocodile
	in the grocery aisle

	Has a tail so long
	it reaches the pickle pile

	He strolls past pepper
	with a sharp-tooth smile

	But pepper makes the gator sneeze
	He yells: \" need a tissue, please!\"

	The cashier says, \"That\’s aisle three,
	around the corner, next to the peas.\"")


		@@messageArray.push Message.new(["http://i.imgur.com/Bnji4mo.jpg", "http://i.imgur.com/0I9irBy.jpg"],
			"StoryTime: Here’s your new story. After you read each line, let your child repeat it after you!",
			"Builder, Builder, build me a house.

	A sweet little house for a sweet little mouse.

	A sweet little mouse and a family too.

	We know that you can and we hope that you __.

	Build it of brick so it's cozy and warm,

	to keep us from harm in a cold winter _____.

	Builder, builder, build our house please.

	As soon as you finish, we'll pay you with cheese!")


		@@messageArray.push Message.new( ["http://i.imgur.com/gbRc8Ur.jpg", "http://i.imgur.com/ouqIZgr.jpg"],
			"StoryTime: This poem's full of rhymes, which help your child build reading skills. Enjoy!",
			"I can tell you a lot about elephants,
	If you want to learn.

	Like—- did you know that elephants
	can get a bad sunburn?

	An elephant can live to be 86 years old,
	And elephants do not forget anything,
	If I remember what I’m told!

	An elephant purrs like a cat,
	if you listen to him,

	And even though he’s big and ___,
	An elephant can swim!

	An elephant has floppy ears,
	But hears things with his feet!

	He finds lots of plants
	And green healthy things to ___!")
		









#Message Series Work! 


	charliePuppy = Array.new

		#the lookup code is the letter (series choice) and series number, ex. p0 for puppy on series numbre 0
	charliePuppy.push Message.new(["http://i.imgur.com/rvjO8sF.jpg", "http://i.imgur.com/dIIDNtU.jpg"],
			"StoryTime: Enjoy your story about Charlie the Puppy!",
			"Charlie the puppy,
	looked in the mirror
	And found a new brown spot!

	\"Oh no!\" he thought,
	\"I look silly with my
	face full of dots!\"

	\"You look good just the way you are,\"
	to him his mommy said,
	\"I’d love you if your tail was
	purple and your spots all red!\"")

	charliePuppy.push Message.new(["http://i.imgur.com/BwjKKGh.jpg", "http://i.imgur.com/C6HfDOc.jpg", "http://i.imgur.com/xo7aMCx.jpg"],
		"StoryTime: You're invited to Charlie the Puppy's birthday party!",
"A puppy named Charlie
threw a birthday party,
and invited his tail-wagging friends.

They danced the Doggy Disco,
And bounced to the Bow-Wow Boogie,
They ate a steak-flavored cake,
and watched a silly cat movie.

Bark! Roof! Bow! Woof!
Can you hear the puppies sing?
In dog language, it’s \"Happy Birthday\" that they’re saying!")


	MessageSeries.new(charliePuppy, "p0")



	bruceMoose = Array.new



	bruceMoose.push Message.new(["http://i.imgur.com/hnIkGzH.jpg"],
	"StoryTime: Well... we were hoping you chose Charlie. We haven't illustrated Bruce yet. Enjoy this for now!",
	"Bruce is the best trumpet player I know. You should hear Bruce blast and blow.\n\nHis cheeks puff out like two balloons. Bruce and the band know hundreds of tunes.\n\nBut there’s a sound that’s even more grand! It’s his mom in the crowd clapping her hands."
	)

	bruceMoose.push Message.new(["http://i.imgur.com/QiKUiAv.jpg"],
	"StoryTime: This is embarassing... here's another unillustrated Bruce poem!\n\n...we warned you this was testing!",
	"Bruce the Moose is on the loose. He\'s riding in a train\'s caboose.\n\nTo escape the Canada cold. He took everything he could hold.\n\nHe\'s bringing his trumpet and his Mama too. Bruce yells, \"To the warm Miami zoo!\""
	)



	MessageSeries.new(bruceMoose, "m0")




end