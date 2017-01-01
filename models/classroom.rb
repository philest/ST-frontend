class Classroom < Sequel::Model(:classrooms)
	plugin :timestamps, :create=>:enrolled_on, :update=>:updated_at, :update_on_create=>true

	many_to_one :teacher
	many_to_one :school
	one_to_many :users

end