module Text

HELP = "HELP NOW"
STOP = "STOP"
TEXT_CMD = "TEXT"
BREAK = "BREAK"


#number of stories to skip
BREAK_LENGTH = 4

START_BREAK = "StoryTime: You got it. We'll message you again in 2 weeks."

END_BREAK = "StoryTime: It's been two weeks on break, now welcome back! When you need to, you can always reply BREAK again.\n\n"

RESUBSCRIBE_SHORT = "StoryTime: Welcome back to StoryTime! We'll keep sending you free stories to read aloud."

RESUBSCRIBE_LONG = "StoryTime: Welcome back to StoryTime! We'll keep sending you free stories to read aloud, continuing from where you left off."

WRONG_BDAY_FORMAT = "We did not understand what you typed. Reply with child's birthdate in MMDDYY format. For questions, reply " + HELP + ". To cancel, reply " + STOP + "."

TOO_YOUNG_SMS = "StoryTime: Sorry, for now we only have msgs for kids ages 3 to 5. We'll contact you when we expand soon! Or reply with birthdate in MMYY format."

MMS_UPDATE = "Okay, you'll now receive just the text of each story. Hope this helps!"




#LATEST EDITED


START_SMS_1 = "Welcome to StoryTime, free pre-k stories by text! You\'ll get "

START_SMS_2 = " stories/week… starting now!\n\nText STOP to quit, or HELP NOW for help. Normal text rates may apply."

START_SPRINT_1 = "Welcome to StoryTime, free pre-k stories by text! You\'ll get "

START_SPRINT_2 = " stories/week, starting now!\n\nText STOP to end, or HELP NOW for help. Normal text rates may apply."

HELP_SMS_1 =  "StoryTime texts free pre-k stories on "

HELP_SMS_2 = ". For help, call us at 561-212-5831.\n\nScreen-time before bed may carry health risks, so read earlier.\n\nReply:\nTEXT for no-pic stories\nBREAK for 2 week break\nSTOP to cancel"

HELP_SPRINT_1 = "StoryTime sends stories on "

HELP_SPRINT_2 = ". For help: 561-212-5831.\n\nScreens before bed may have health risks, so read early.\n\nReply:\nTEXT for no-pic stories\nSTOP to end"
 
NO_OPTION = "StoryTime: Sorry, this service is automatic. We didn\'t understand that.\n\nReply:\nHELP NOW for questions\nSTOP to cancel"






STOPSMS = "Okay, we\'ll stop texting you stories. Thanks for trying us out! If you have any feedback, please contact our director, Phil, at 561-212-5831."

TIME_SPRINT = "ST: Great, last question! When do you want to get stories (e.g. 5:00pm)? 

Screentime w/in 2hrs before bedtime can carry health risks, so please read earlier."

TIMESMS = "StoryTime: Great, last question! When do you want to receive stories (e.g. 5:00pm)? 

Screentime within 2hrs before bedtime can delay children's sleep and carry health risks, so please read earlier."

BAD_TIME_SMS = "We did not understand what you typed. Reply with your preferred time to get stories (e.g. 5:00pm). 
For questions about StoryTime, reply " + HELP + ". To stop messages, reply " + STOP + "."
	
BAD_TIME_SPRINT = "We did not understand what you typed. Reply with your preferred time to get stories (e.g. 5:00pm). Reply " + HELP + "for help."
	
REDO_BIRTHDATE = "When was your child born? For age appropriate stories, reply with your child's birthdate in MMYY format (e.g. 0912 for September 2012)."

SPRINT = "Sprint Spectrum, L.P."

SPRINT_QUERY_STRING = 'Sprint%20Spectrum%2C%20L%2EP%2E'


GOOD_CHOICE = "Great, it's on the way!"

BAD_CHOICE = "StoryTime: Sorry, we didn't understand that. Reply with the letter of the story you want.

For help, reply HELP NOW."

POST_SAMPLE = "StoryTime: Hi! StoryTime's an automated service, but, if you want to learn more, contact our director, Phil, at 561-212-5831."

NO_SIGNUP_MATCH = "StoryTime: Sorry, we didn't understand that. Text STORY to signup for free stories by text, or text SAMPLE to receive a sample"

SAMPLE = "SAMPLE"

EXAMPLE = "EXAMPLE"

FIRST = "FIRST"

GREET_SMS  = "StoryTime: Thanks for trying out StoryTime, free stories by text! Your two page sample story is on the way :)"

CONFIRMED_STICKING = "StoryTime: Great, we'll keep sending you free stories!"

SPANISH = "SP"

ENGLISH = "EN"

URL = "http://joinstorytime.herokuapp.com/"

IMAGE_URL = "http://joinstorytime.herokuapp.com/images/"

FIRST_MMS = ["http://www.joinstorytime.herokuapp.com/images/d1.jpg"]

THE_FINAL_MMS = "http://www.joinstorytime.herokuapp.com/images/d1.jpg"

SAMPLE_SMS = "Today in class, we talked about the moon and space. When you see orange bubbles in tonight's story, point and ask 'what's this?' or 'what's going on here?'\n-Ms. Wilson\n\nThanks for trying StoryTime!"

SAMPLE_SPRINT_SMS = "Today in class, we talked about the moon. As you read and see orange bubbles, point and ask 'what's going on here?'\n-Ms. Wilson\n\nThanks for trying StoryTime!"

EXAMPLE_SMS = "Thanks for trying out StoryTime, free rhyming stories by text! Enjoy your sample story about Devon's scoop!"

#types for new_text_worker
STORY = "story"
NOT_STORY = "not_story"


end