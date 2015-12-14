#  spec/factories.rb 	                      Phil Esterman		
# 
#  Define a set of factories for creating test model 
#  instances. 
#  --------------------------------------------------------

FactoryGirl.define do

  factory :user do
    phone  "+15613334444"
    days_per_week  2
  end

  factory :experiment do
  end


  factory :variation do

  	  factory :variation_with_experiment do |t|
		association :experiment
	  end

	  factory :variation_with_user do |t| 
	  	association :user
	  end

  end







end