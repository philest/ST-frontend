class User < ActiveRecord::Base
	has_many :variations
	has_many :experiments, through: :variations 
end