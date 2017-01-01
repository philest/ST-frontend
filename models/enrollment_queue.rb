class EnrollmentQueue < Sequel::Model(:enrollment_queue)
	plugin :timestamps, :create=>:created_at, :update=>:updated_at, :update_on_create=>true
	plugin :association_dependencies
	one_to_one :user

	add_association_dependencies user: :nullify

end