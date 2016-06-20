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
		   'phone_1' => "5612125888",
		   :name_2 => "Aub",
		   :phone_2 => "5612125999",
		   "teacher_prefix" => "Ms.",
		   "teacher_name" => "Jones"
		 }

# binding.pry


HTTParty.post(ENV['birdv_url'], body: params)
