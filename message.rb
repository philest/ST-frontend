require_relative './messageSeries'
require_relative './i18n/constants'

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

		#banana bread
		@@messageArray.push Message.new([Text::IMAGE_URL+"bb1.jpg", Text::IMAGE_URL+"bb2.jpg"],
		"StoryTime: Talking grows your child's brain! When you see an orange bubble, point to the picture and ask \'what's this?\' or \'what's going on here?\'",
		"Jasmine baked banana bread.\n\nIt was bigger than her head\n\nand huger than a hippo-potamus\n\nand larger than a giant octopus!\n\nJasmine thinks it's only fair\n\nfor her and all her friends to share.")

		#croc in grocery shop
		@@messageArray.push Message.new([Text::IMAGE_URL+"ch1.jpg", Text::IMAGE_URL+"ch2.jpg"],
		"StoryTime: Here's tonight's story about a croc who shops! See if your child can tell you what's going on in each page.",
		"There's a huge hungry croc\n\nin the grocery shop\n\nand I think he's coming to chomp me!\n\n\nHe licks his big lips,\n\nand swings his big hips,\n\nbut this croc only wants broccoli!")

		#superheroes
		@@messageArray.push Message.new([Text::IMAGE_URL+"hero1.jpg", Text::IMAGE_URL+"hero2.jpg"],
		"StoryTime: Enjoy tonight's superhero story!\n\nWhenever you talk or play with your child, you're helping her grow into a super-reader!",
		"SuperSarah can break a brick wall\n\nwith her pinky finger.\n\nSuperSam can run to China\n\nand be back before dinner.\n\n\nMy superpower is telling funny jokes\n\nuntil you fall down.\n\nI'll make you laugh so much,\n\nyou'll be rolling on the ground!")
		
		#pizza aliens
		@@messageArray.push Message.new([Text::IMAGE_URL+"pizza1.jpg", Text::IMAGE_URL+"pizza2.jpg"],
		"StoryTime: Be careful when you throw a pizza pie!",
		"If you throw a pizza\n\nup into the sky\n\ndon't expect to get it back\n\n\nAliens way up high\n\nwill eat it for a cheesy snack!")


	#Message Series 
		
		baboon = Array.new
		dino = Array.new

		#babooon in pocket
		baboon.push Message.new([Text::IMAGE_URL+"b1.jpg", Text::IMAGE_URL+"b2.jpg"],
		"StoryTime: Tim stuffs a lot in his pocket! Your child loves being silly. Take turns saying the silly things you could find in your pocket.",
		"Tim's mom told him\n\nto clean his room.\n\nUnder his bed, he found a baboon.\n\n\nTim's mom told him\n\nto clean his pocket.\n\nHe found a hippo, two tacos,\n\nand a space rocket!")
	
		#dino tea party...
		dino.push Message.new([Text::IMAGE_URL+"dino1.jpg", Text::IMAGE_URL+"dino2.jpg"],
		"StoryTime: You're invited to to a dinosaur tea party!",
		"The dinosaurs have a tea party!\n\nwill you come with me?\n\n\nwe'll stomp, and roar,\n\nand shake our tails,\n\nand sip on cups of tea!")


	MessageSeries.new(baboon, "t0")
	MessageSeries.new(dino, "d0")







end