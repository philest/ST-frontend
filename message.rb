


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
	



end