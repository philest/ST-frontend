class SchoolSession < Sequel::Model(:school_sessions)
	plugin :timestamps, :create=>:created_at, :update=>:updated_at, :update_on_create=>true

	many_to_one :school
end