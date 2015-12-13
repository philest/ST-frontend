class User < ActiveRecord::Base
	has_one :variation
	has_one :experiment, through: :variation
end