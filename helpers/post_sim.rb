#
#
# Simulate a post request to birdv/enroll 
# - - - - - - - -- - -- - - - - -- 

require 'httparty'
require 'dotenv'
Dotenv.load

params = { :name_0 => "Phil",
		   :phone_0 => "5612125831",
		   'name_1' => "David",
		   'phone_1' => "8186897323",
		   :name_2 => "Aub",
		   :phone_2 => "3013328953",
		   "teacher_prefix" => "Ms.",
		   "teacher_signature" => "Jones"
		 }

# params = {
# 	:name_0 => "AssWipe", 
# 	:phone_0 => "keyboard MADNESS!", 
# 	:teacher_prefix => "Ms.",
# 	:teacher_signature => "Jones"
# }

# binding.pry


HTTParty.post(ENV['quailtime_url'], body: params)
