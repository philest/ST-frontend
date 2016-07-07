#
#
# Simulate a post request to birdv/enroll 
# - - - - - - - -- - -- - - - - -- 

require 'httparty'
require 'dotenv'
Dotenv.load

params = { :name_0 => "Phil Esterman",
		   :phone_0 => "5612125831",
		   'name_1' => "David McPeek",
		   'phone_1' => "8186897323",
		   :name_2 => "Aubrey Wahl",
		   :phone_2 => "3013328953",
		   :name_3 => "Ben McPeek", 
		   :phone_3 => "8183216278",
		   :name_4 => "Akhil Placeholder",
		   :phone_4 => "8145744864",
		   :name_5 => "Raquel McPeek",
		   :phone_5 => "8188049338",
		   :name_6 => "Emily McPeek", 
		   :phone_6 => "8184292090",
		   "teacher_signature" => "Ms. Jones",
		   "teacher_email" => "david.mcpeek@yale.edu",
		   :name_7 => "Dud One", 
		   :phone_7 => "123456789",
   		   :name_8 => "Dud Two", 
		   :phone_8 => "999999999",
   		   :name_9 => "Dud Three", 
		   :phone_9 => "987654321",


		 }


HTTParty.post(ENV['enroll_url'], body: params)
